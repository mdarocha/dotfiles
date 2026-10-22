---
name: markdown-prose-humanize
description: "Run a humanizer pass over prose just added to a doc file"
condition: ["(?m)\\S"]
question: >-
  Answer yes unless this text is working material only another AI agent reads. Agent-only material:
  `local://` notes, plans, research or result reports handed between agents, task context, and chunked
  batch/work files under scratch directories such as `.work/`. Everything else is for a human and gets yes:
  READMEs, docs, reports, data lists, checklists, skill/command/rule/AGENTS.md files, and PR, issue, or commit text,
  including drafts of those in `/tmp` or `local://pr-*` files. When unsure, answer yes.
scope: ["tool:edit", "tool:write", "tool:ast_edit"]
interruptMode: never
globs:
  - "*.{md,mdx,markdown,txt}"
---

You just wrote or edited prose in a doc file. Before moving on, load the `humanizer` skill
and run its process — mark the tells, draft the rewrite, check the draft, write the final
version — over the lines you just added or changed in this file.

Watch especially for the patterns that keep surviving a first draft here: a mechanical
bold label on every list item, a "no X/Y/Z" aside naming tools nobody asked about, a
not-X-but-Y contrast, a staged run-up before the actual point, or a stock AI word. If
none of that applies, say so and move on — this is not a license to rewrite prose that
is already plain.

Do the pass now, in this same turn, not after the user points it out.
