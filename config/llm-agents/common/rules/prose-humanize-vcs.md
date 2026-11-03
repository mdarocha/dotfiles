---
name: prose-humanize-vcs
description: "Run a prose-check pass over commit messages and PR text before sending"
condition:
  - "git\\s+commit(?![^\\n]*--no-edit)"
  - "gh\\s+(?:pr|issue)\\s+(?:create|edit|comment)\\b(?![^\\n]*--help)"
  - "\"op\"\\s*:\\s*\"pr_create\""
scope: ["tool:bash", "tool:github"]
interruptMode: tool-only
---

A commit message or PR title/body is prose the user reads. Before sending it, load the
`prose-check` skill (skip if already loaded this session) and check the text against it. Keep
it plain and specific to what actually changed.
