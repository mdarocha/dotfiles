import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const EDIT_TOOLS: Record<string, true> = { edit: true, write: true, ast_edit: true, notebook_edit: true };
const MAX_FINDINGS = 12;
const DENSITY_MIN_COMMENTS = 4;
const DENSITY_RATIO = 0.25;
const NARRATION_MIN_SHARED = 2;
const NARRATION_MIN_FRACTION = 0.5;

const LINE_COMMENT_PREFIXES: Array<[RegExp, string[]]> = [
	[
		/\.(?:c|h|cc|cpp|cxx|hpp|cs|java|kt|kts|scala|swift|go|rs|zig|ts|tsx|js|jsx|mjs|cjs|vue|svelte|php|dart|proto|gradle|css|scss|less|fs|fsx|pas|dpr|pp|d|mm|groovy)$/i,
		["//", "/*"],
	],
	[
		/\.(?:py|rb|sh|bash|zsh|fish|nix|pl|pm|r|jl|ps1|tf|yaml|yml|toml|ini|mk|cmake|ex|exs|csh|tcsh|hcl|graphql|gql)$/i,
		["#"],
	],
	[/\.(?:sql|hs|elm|lua|ada|adb|ads)$/i, ["--"]],
	[/\.(?:el|lisp|scm|clj|cljs|asm)$/i, [";"]],
	[/\.erl$/i, ["%"]],
	[/\.mli?$/i, ["(*"]],
	[/\.(?:f90|f95|f03|f08)$/i, ["!"]],
	[/\.(?:vb|vbs|bas)$/i, ["'"]],
	[/\.(?:html?|xml|xhtml|svg)$/i, ["<!--"]],
	[/(?:^|\/)(?:Makefile|Dockerfile)$/, ["#"]],
];

/** Doc comments carry a contract, so they are exempt from the density budget. */
const DOC_MARKERS = [/^\/\/[/!]/, /^\/\*[*!]/, /^\*/, /^#'/, /^--\|/, /^"""/, /^'''/];

const SLOP_RULES: Array<[RegExp, string]> = [
	[/^(?:step|phase|part)\s*\d+\b/i, "phase header"],
	[/^[-=*_~+#]{6,}$/, "decorative separator"],
	[
		/^(?:changed from|used to be|previously[\s,]|now (?:handles|uses|returns|does|supports|works)|renamed (?:from|to)|no longer|was:|new:|added:|removed:|updated:|fixed:)/i,
		"edit history",
	],
	[
		/^(?:imports?|exports?|helpers?|constants?|globals?|utils?|setup|teardown|cleanup|initialization|main|config|interfaces?|props|state|handlers?|getters?|setters?|variables?|functions?|classes?|dependencies)\s*:?$/i,
		"structural label",
	],
	[
		/^(?:loop through|iterate over|initialize|increment|decrement|return the|call the|create (?:a|an|the) new|check if|set the|get the|add the|remove the|update the|delete the|assign the|declare|define the|import the|export the|instantiate|print the|log the|convert the|parse the|validate the|handle the|process the)\b/i,
		"narrates the next line",
	],
	[/^[@\\](?:param|arg|argument)\s+\S+\s*[-–—:]?\s*(?:the|a|an)\s+\w+$/i, "doc restates name and type"],
	[/^[@\\]returns?\s+(?:the|a|an)\s+\w+$/i, "doc restates name and type"],
	[
		/^(?:as requested|as you asked|for clarity|for readability|best practice|note that this is|this is a placeholder|for demonstration|unchanged)\b/i,
		"assistant chatter",
	],
	[
		/^(?:if|for|while|switch|return|const|let|var|def|fn|func|class|import|from|print|console\.log|echo)\b.*[;{)]$/,
		"commented-out code",
	],
];

const STOPWORDS = new Set([
	"the", "a", "an", "and", "or", "of", "to", "in", "for", "on", "with", "this", "that",
	"it", "is", "are", "be", "we", "then", "each", "all", "new", "from", "by", "as", "if",
	"into", "its", "so", "not", "no", "do", "does", "use", "using", "value", "values",
]);

export interface Finding {
	path: string;
	line: number;
	text: string;
	why: string;
}

export interface AddedLine {
	line: number;
	text: string;
}

function prefixesFor(path: string): string[] | undefined {
	for (const [pattern, prefixes] of LINE_COMMENT_PREFIXES) {
		if (pattern.test(path)) {
			return prefixes;
		}
	}
	return undefined;
}

function commentBody(text: string, prefixes: string[]): string | undefined {
	const trimmed = text.trim();
	for (const prefix of prefixes) {
		if (trimmed.startsWith(prefix)) {
			return trimmed.slice(prefix.length).replace(/^[/!*\s]+/, "").replace(/\s*(?:\*\/|\*\)|-->)\s*$/, "").trim();
		}
	}
	if (trimmed.startsWith("*") && !trimmed.startsWith("*/")) {
		return trimmed.slice(1).trim();
	}
	return undefined;
}

/** Splits identifiers into comparable word stems: `parseUserId` -> parse, user, id. */
function stems(text: string): string[] {
	return text
		.replace(/([a-z0-9])([A-Z])/g, "$1 $2")
		.split(/[^A-Za-z0-9]+/)
		.map(word => word.toLowerCase())
		.filter(word => word.length >= 3 && !STOPWORDS.has(word))
		.map(word => word.replace(/(?:ing|ed|es|s)$/, ""))
		.filter(word => word.length >= 3);
}

/** True when the comment says nothing the following statement does not already say. */
export function narratesNextLine(body: string, nextCode: string): boolean {
	const commentStems = new Set(stems(body));
	if (commentStems.size < NARRATION_MIN_SHARED) {
		return false;
	}
	const codeStems = new Set(stems(nextCode));
	let shared = 0;
	for (const stem of commentStems) {
		if (codeStems.has(stem)) {
			shared++;
		}
	}
	return shared >= NARRATION_MIN_SHARED && shared / commentStems.size >= NARRATION_MIN_FRACTION;
}

export function auditFile(path: string, added: AddedLine[]): Finding[] {
	const prefixes = prefixesFor(path);
	if (!prefixes) {
		return [];
	}

	const findings: Finding[] = [];
	let narrative = 0;
	let code = 0;

	for (let i = 0; i < added.length; i++) {
		const { line, text } = added[i];
		const body = commentBody(text, prefixes);

		if (body === undefined) {
			if (text.trim().length > 0) {
				code++;
			}
			continue;
		}
		if (!DOC_MARKERS.some(marker => marker.test(text.trim()))) {
			narrative++;
		}
		if (body.length === 0) {
			continue;
		}

		const slop = SLOP_RULES.find(([pattern]) => pattern.test(body));
		if (slop) {
			findings.push({ path, line, text: text.trim(), why: slop[1] });
			continue;
		}

		const next = added.slice(i + 1).find(entry => {
			const following = entry.text.trim();
			return following.length > 0 && commentBody(entry.text, prefixes) === undefined;
		});
		if (next && narratesNextLine(body, next.text)) {
			findings.push({ path, line, text: text.trim(), why: "restates the line below it" });
		}
	}

	if (narrative >= DENSITY_MIN_COMMENTS && narrative / Math.max(code, 1) > DENSITY_RATIO) {
		findings.push({
			path,
			line: added[0]?.line ?? 1,
			text: `${narrative} narrative comment lines against ${code} lines of code`,
			why: "comment density",
		});
	}

	return findings;
}

function git(args: string[], cwd: string): string | undefined {
	const result = Bun.spawnSync({ cmd: ["git", ...args], cwd, stdout: "pipe", stderr: "ignore" });
	return result.success ? result.stdout.toString() : undefined;
}

export function parseAddedLines(diff: string): AddedLine[] {
	const added: AddedLine[] = [];
	let line = 0;
	for (const row of diff.split("\n")) {
		const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)/.exec(row);
		if (hunk) {
			line = Number(hunk[1]);
			continue;
		}
		if (row.startsWith("+++") || row.startsWith("---")) {
			continue;
		}
		if (row.startsWith("+")) {
			added.push({ line, text: row.slice(1) });
			line++;
			continue;
		}
		if (!row.startsWith("-") && !row.startsWith("\\")) {
			line++;
		}
	}
	return added;
}

function addedLinesFor(path: string, cwd: string): AddedLine[] {
	const tracked = git(["ls-files", "--error-unmatch", "--", path], cwd) !== undefined;
	if (tracked) {
		const diff = git(["diff", "-U0", "HEAD", "--", path], cwd);
		return diff ? parseAddedLines(diff) : [];
	}

	return readFileSync(resolve(cwd, path), "utf8")
		.split("\n")
		.map((text, index) => ({ line: index + 1, text }));
}

function remediation(findings: Finding[]): string {
	const shown = findings.slice(0, MAX_FINDINGS);
	const lines = shown.map(
		(finding, index) => `${index + 1}. ${finding.path}:${finding.line} — ${finding.why}\n   ${finding.text}`,
	);
	const hidden = findings.length - shown.length;

	return [
		"Comment audit of this session's diff found comments the project policy rejects.",
		"",
		lines.join("\n"),
		hidden > 0 ? `\n${hidden} further finding(s) not listed.` : undefined,
		"",
		"For each one: delete it, or keep it only if it states a *why* that is invisible",
		"locally — a constraint, an edge case, a linked workaround, or a public-surface",
		"contract. Rewording a restatement does not fix it.",
		"",
		"Apply the edits now, then report which you removed and which you kept and why.",
		"A `comment density` finding means the diff adds narration in bulk: cut it down",
		"rather than editing individual lines.",
	]
		.filter(part => part !== undefined)
		.join("\n");
}

export default function (pi: ExtensionAPI) {
	pi.setLabel("Comment Audit");

	const touched = new Set<string>();

	pi.on("tool_execution_start", async event => {
		if (!EDIT_TOOLS[event.toolName]) {
			return;
		}
		const args = event.args as { path?: unknown; paths?: unknown } | undefined;
		for (const value of [args?.path, ...(Array.isArray(args?.paths) ? args.paths : [])]) {
			if (typeof value === "string" && value.length > 0) {
				touched.add(value);
			}
		}
	});

	pi.on("session_stop", async (event, ctx) => {
		if (event.stop_hook_active || process.env.OMP_COMMENT_AUDIT === "0" || touched.size === 0) {
			return undefined;
		}

		const paths = [...touched];
		touched.clear();

		try {
			if (git(["rev-parse", "--is-inside-work-tree"], ctx.cwd) === undefined) {
				return undefined;
			}

			const findings = paths.flatMap(path => auditFile(path, addedLinesFor(path, ctx.cwd)));
			if (findings.length === 0) {
				return undefined;
			}

			return { continue: true, additionalContext: remediation(findings) };
		} catch {
			return undefined;
		}
	});
}
