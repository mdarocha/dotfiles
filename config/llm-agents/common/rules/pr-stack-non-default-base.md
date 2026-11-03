---
name: pr-stack-non-default-base
description: "A PR whose base is not a default branch belongs to a stack: link it with gh stack"
condition:
  - "\\bgh\\s+pr\\s+(?:create|edit)\\b"
  - "\"op\"\\s*:\\s*\"pr_create\""
question: >-
  Answer yes only if this command creates or edits a pull request and explicitly sets its base branch (`--base`, `-B`, or a JSON `base` field) to a branch that is not the repository's default branch (main, master, develop, trunk, or similar). Answer no when no base is set, when the base is a default branch, or when the text only shows such a command as an example, in a file, or in a quoted string.
scope: ["tool:bash", "tool:github"]
interruptMode: never
---

This PR targets a branch that is not a default branch, so it is one layer of a stack. Do not
describe the stack in the PR body. Link the PRs as a native GitHub stack, bottom to top, as
described in the "Stacked pull requests" section of the `github` skill:

```bash
gh pr view <number> --json number,baseRefName,headRefName,state   # check each base/head chain first
gh stack link --remote origin <bottom-pr> <next-pr> ... <top-pr>
```

Exit code 9 means the repository has no stacked PRs enabled, so do not claim the PRs are linked.
