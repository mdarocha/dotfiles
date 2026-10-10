# llm-agents

A Home Manager module that installs AI coding agents and gives them all the same
instructions, tools, and skills.

Pick the agents you want:

```nix
mdarocha.llm-agents.enabledAgents = [ "claude" "copilot" "cursor" "omp" ];
```

The agent packages come from [`numtide/llm-agents.nix`][llm-agents]. This module
adds the configuration on top.

## What every agent gets

The shared pieces live in `common/`:

- `instructions.md` is installed as each agent's global instructions file
  (`CLAUDE.md`, `AGENTS.md`, and so on).
- `environment/` defines the packages on the agent's `PATH`, a Python environment,
  and a Chromium build. The agent is told what's available, so it doesn't try to
  install things.
- Everything in `skills/`, plus a few from upstream skill repos, is linked into each
  agent's skills directory.
- `rules/` holds short rules that fire when the agent does something that matches,
  like editing a doc file. oh-my-pi supports them natively, and Claude Code gets them
  through a hook.
- Each agent's binary is a small wrapper (`agent-wrapper.nix`) that runs it behind a
  local proxy (`network-log/`). When a session ends, the hosts it contacted are
  appended to `~/<agent home>/network-log/`, for example
  `~/.claude/network-log/network.log`. The proxy only records traffic. Each agent's
  instructions say where its log is.

## Agents

- oh-my-pi (`oh-my-pi/`) installs [`omp`][omp] with generated settings. Your own
  `~/.omp/agent/config.yml` is loaded after them, so changes made in the UI win. It
  also installs [pi-automode][pi-automode], which checks every tool call against the
  policy in `automode/settings.nix` before it runs. Fixed rules decide the simple
  cases, and a small classifier model decides the rest.
- Claude Code (`claude-code/`) installs [`claude`][claude-code] and enforces the
  shared rules through a hook. On machines that already have their own `claude`, set
  `claude-code.package = null` to install only the configuration.
- Copilot CLI (`copilot-cli/`) installs [`copilot`][copilot-cli].
- Cursor Agent (`cursor-agent/`) installs [`cursor-agent`][cursor-agent]. It has no
  global instructions file, so the wrapper adds a directory holding one to every
  session.

[llm-agents]: https://github.com/numtide/llm-agents.nix
[pi-automode]: https://github.com/czottmann/pi-automode
[omp]: https://github.com/can1357/oh-my-pi
[copilot-cli]: https://github.com/github/copilot-cli
[claude-code]: https://github.com/anthropics/claude-code
[cursor-agent]: https://cursor.com/
