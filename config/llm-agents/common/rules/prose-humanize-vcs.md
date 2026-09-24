---
name: prose-humanize-vcs
description: "Run a humanizer pass over commit messages and PR text before sending"
condition:
  - "git\\s+commit(?![^\\n]*--no-edit)"
  - "gh\\s+(?:pr|issue)\\s+(?:create|edit|comment)\\b"
  - "\"op\"\\s*:\\s*\"pr_create\""
scope: ["tool:bash", "tool:github"]
interruptMode: never
---

A commit message or PR title/body is prose the user reads. Before sending it, load
the `humanizer` skill and check the text for the same tells that show up in docs: bold
labels on every list item, a not-X-but-Y contrast, a staged summary paragraph, a stock
AI word. Keep it plain and specific to what actually changed.
