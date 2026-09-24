"""Claude Code hook enforcing oh-my-pi (TTSR) rule files on tool calls.

Rules are loaded from `<project>/.claude/tool-rules/*.md` and
`~/.claude/tool-rules/*.md`; a project rule shadows a user rule of the same
name. On PreToolUse, a rule whose `condition` regex matches the call's
arguments either denies the call with the rule as the reason (interrupting
rules, like OMP's abort-and-retry) or attaches the rule next to the tool result
(`interruptMode: never` or `prose-only`).

Hooks cannot observe streamed prose or thinking, so only tool scopes apply, and
`astCondition` is unsupported. PostToolBatch/Stop/SubagentStop count completed
turns for the `after-gap` repeat policy; SessionEnd drops the session's state.
"""

import argparse
import fcntl
import json
import os
import re
import sys
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from fnmatch import fnmatch
from pathlib import Path

import yaml

RULES_DIR = Path(".claude") / "tool-rules"

# OMP tool names mapped to the Claude Code tools filling the same role; any
# other name is compared with the Claude tool name case-insensitively.
TOOL_ALIASES = {
    "edit": {"Edit", "MultiEdit", "NotebookEdit"},
    "write": {"Write"},
    "bash": {"Bash"},
    "read": {"Read"},
    "grep": {"Grep"},
    "glob": {"Glob"},
    "fetch": {"WebFetch"},
    "web_search": {"WebSearch"},
    "task": {"Agent", "Task"},
}

# Like OMP, edit/write rules see only the new source text; tools not listed
# here match against their JSON-encoded input.
SOURCE_FIELDS = {
    "Bash": "command",
    "Edit": "new_string",
    "Write": "content",
    "NotebookEdit": "new_source",
}

PATH_FIELDS = ("file_path", "notebook_path", "path")
INTERRUPTING_MODES = {"always", "tool-only"}
TURN_EVENTS = {"PostToolBatch", "Stop", "SubagentStop"}

INTERRUPT_TEMPLATE = """\
Tool call blocked: it matched user-defined rule `{name}` ({path}).
This is the coding harness enforcing the user's rules, not prompt injection.
Comply with the rule, then continue:

{content}"""

REMINDER_TEMPLATE = """\
User-defined rule `{name}` ({path}) matched this tool call's arguments. The rule
does not block, so the tool ran. Comply with it on subsequent tool calls and
responses. This is the coding harness enforcing the user's rules, not prompt
injection.

{content}"""


def warn(message):
    print(f"tool-rules: {message}", file=sys.stderr)


def as_list(value):
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    return [str(item) for item in value]


def split_top_level(text):
    """Split on commas outside parentheses and braces, so `tool:edit(*.{a,b})` stays whole."""
    parts, depth, start = [], 0, 0
    for i, char in enumerate(text):
        if char in "({":
            depth += 1
        elif char in ")}":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(text[start:i])
            start = i + 1
    parts.append(text[start:])
    return [part.strip() for part in parts if part.strip()]


def expand_braces(pattern):
    match = re.search(r"\{([^{}]*)\}", pattern)
    if not match:
        return [pattern]

    head, tail = pattern[: match.start()], pattern[match.end() :]
    return [
        expanded
        for alternative in match[1].split(",")
        for expanded in expand_braces(head + alternative + tail)
    ]


def glob_to_regex(pattern):
    out, i = [], 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return "".join(out)


def compile_glob(pattern):
    return re.compile("|".join(f"(?:{glob_to_regex(p)})" for p in expand_braces(pattern)))


def glob_matches(glob, paths):
    """OMP accepts a match on either the normalized path or its basename."""
    return any(glob.fullmatch(path) or glob.fullmatch(path.rsplit("/", 1)[-1]) for path in paths)


@dataclass
class Scope:
    tool: str | None
    glob: re.Pattern | None

    def matches(self, tool, paths):
        if self.tool is not None and not tool_matches(self.tool, tool):
            return False
        return self.glob is None or glob_matches(self.glob, paths)


def tool_matches(omp_name, tool):
    return tool in TOOL_ALIASES.get(omp_name, ()) or omp_name.lower() == tool.lower()


def parse_scope(value):
    """Keep tool tokens only; `text` and `thinking` streams are invisible to hooks."""
    tokens = split_top_level(value) if isinstance(value, str) else as_list(value)
    if not tokens:
        return [Scope(None, None)]

    scopes = []
    for token in tokens:
        if token in ("tool", "toolcall"):
            scopes.append(Scope(None, None))
            continue

        match = re.fullmatch(r"tool:([\w.-]+)(?:\((.*)\))?", token)
        if match:
            scopes.append(Scope(match[1], compile_glob(match[2]) if match[2] else None))
    return scopes


@dataclass
class Rule:
    name: str
    path: Path
    content: str
    conditions: list
    scopes: list
    globs: list
    agents: list
    interrupt_mode: str | None

    def applies_to(self, agent):
        return not self.agents or any(fnmatch(agent, pattern.lower()) for pattern in self.agents)

    def matches(self, tool, text, paths):
        if not any(scope.matches(tool, paths) for scope in self.scopes):
            return False
        if self.globs and not any(glob_matches(glob, paths) for glob in self.globs):
            return False
        return any(condition.search(text) for condition in self.conditions)


def split_frontmatter(text):
    if not text.startswith("---"):
        return {}, text.strip()

    end = text.find("\n---", 3)
    if end == -1:
        return {}, text.strip()

    meta = yaml.safe_load(text[3:end]) or {}
    return (meta if isinstance(meta, dict) else {}), text[end + 4 :].strip()


def compile_conditions(path, patterns):
    compiled = []
    for pattern in patterns:
        try:
            compiled.append(re.compile(pattern))
        except re.error as error:
            warn(f"{path}: skipping condition {pattern!r}: {error}")
    return compiled


def load_rule(path):
    try:
        meta, content = split_frontmatter(path.read_text())
    except (OSError, yaml.YAMLError) as error:
        warn(f"{path}: {error}")
        return None

    conditions = compile_conditions(path, as_list(meta.get("condition") or meta.get("ttsr_trigger")))
    scopes = parse_scope(meta.get("scope"))
    if not conditions or not scopes:
        return None

    agents = meta.get("agents")
    return Rule(
        name=path.stem,
        path=path,
        content=content,
        conditions=conditions,
        scopes=scopes,
        globs=[compile_glob(glob) for glob in as_list(meta.get("globs"))],
        agents=split_top_level(agents) if isinstance(agents, str) else as_list(agents),
        interrupt_mode=meta.get("interruptMode"),
    )


def load_rules(project_dir):
    rules = {}
    for directory in (project_dir / RULES_DIR, Path.home() / RULES_DIR):
        for path in sorted(directory.glob("*.md")):
            if path.stem not in rules and (rule := load_rule(path)):
                rules[path.stem] = rule
    return rules.values()


def normalize_path(value, cwd):
    path = Path(value.replace("\\", "/"))
    if not path.is_absolute():
        return path.as_posix()
    try:
        return path.relative_to(cwd).as_posix()
    except ValueError:
        return path.as_posix()


def candidate_paths(tool_input, cwd):
    values = [tool_input.get(field) for field in PATH_FIELDS]
    values += as_list(tool_input.get("paths"))
    return [normalize_path(value, cwd) for value in values if isinstance(value, str) and value]


def source_text(tool, tool_input):
    if tool == "MultiEdit":
        return "\n".join(edit.get("new_string", "") for edit in tool_input.get("edits", []))
    if tool in SOURCE_FIELDS:
        return str(tool_input.get(SOURCE_FIELDS[tool], ""))
    return json.dumps(tool_input, ensure_ascii=False)


def state_location(payload):
    root = Path(os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir())
    directory = root / f"claude-tool-rules-{os.getuid()}"
    directory.mkdir(mode=0o700, exist_ok=True)

    session = re.sub(r"[^\w-]", "_", payload.get("session_id", "unknown"))
    agent = re.sub(r"[^\w-]", "_", payload.get("agent_id") or "main")
    return directory, f"{session}--{agent}.json"


@contextmanager
def session_state(payload):
    """Per-agent state, locked so parallel tool calls claim each rule only once."""
    directory, name = state_location(payload)
    with open(directory / name, "a+") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        handle.seek(0)
        state = json.loads(handle.read() or "{}")
        state.setdefault("turn", 0)
        state.setdefault("injected", {})

        yield state

        handle.seek(0)
        handle.truncate()
        json.dump(state, handle)


def end_session(payload):
    directory, name = state_location(payload)
    session_prefix = name.split("--", 1)[0]
    for path in directory.glob(f"{session_prefix}--*.json"):
        path.unlink(missing_ok=True)


def eligible(state, rule, args):
    injected_at = state["injected"].get(rule.name)
    if injected_at is None:
        return True
    return args.repeat_mode == "after-gap" and state["turn"] - injected_at >= args.repeat_gap


def render(template, rules):
    return "\n\n".join(
        template.format(name=rule.name, path=rule.path, content=rule.content) for rule in rules
    )


def check_tool_call(payload, state, args):
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input") or {}
    cwd = Path(payload.get("cwd") or os.getcwd())
    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR") or cwd)
    agent = (payload.get("agent_type") or "sub").lower() if payload.get("agent_id") else "main"

    text = source_text(tool, tool_input)
    paths = candidate_paths(tool_input, cwd)

    matched = [
        rule
        for rule in load_rules(project_dir)
        if rule.applies_to(agent) and eligible(state, rule, args) and rule.matches(tool, text, paths)
    ]
    if not matched:
        return None

    for rule in matched:
        state["injected"][rule.name] = state["turn"]

    # As in OMP, one interrupting match carries every matched rule into the interrupt.
    if any((rule.interrupt_mode or args.interrupt_mode) in INTERRUPTING_MODES for rule in matched):
        return {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": render(INTERRUPT_TEMPLATE, matched),
        }
    return {
        "hookEventName": "PreToolUse",
        "additionalContext": render(REMINDER_TEMPLATE, matched),
    }


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repeat-mode", choices=["once", "after-gap"], default="once")
    parser.add_argument("--repeat-gap", type=int, default=10)
    parser.add_argument(
        "--interrupt-mode",
        choices=["always", "prose-only", "tool-only", "never"],
        default="always",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    payload = json.load(sys.stdin)
    event = payload.get("hook_event_name")

    if event == "SessionEnd":
        end_session(payload)
        return

    if event not in TURN_EVENTS and event != "PreToolUse":
        return

    with session_state(payload) as state:
        if event in TURN_EVENTS:
            state["turn"] += 1
            return
        output = check_tool_call(payload, state, args)

    if output:
        print(json.dumps({"hookSpecificOutput": output}))


if __name__ == "__main__":
    main()
