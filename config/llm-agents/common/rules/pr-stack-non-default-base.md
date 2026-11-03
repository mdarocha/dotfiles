---
name: pr-stack-non-default-base
description: "A PR whose base is not a default branch belongs to a stack: link it with gh stack"
condition:
  - |-
    \bgh\b[\s\S]*?\bpr\s+create\b[\s\S]*?(?:\s--base(?:=|\s+)|\s-B\s*)[\\"']*(?!(?:main|master|develop|development|dev|trunk|default|staging|production|stable)(?![\w./-]))[^\s"'\\;&|)]+
  - |-
    \\?"op\\?"\s*:\s*\\?"pr_create\\?"[\s\S]*?\\?"base\\?"\s*:\s*\\?"(?!(?:main|master|develop|development|dev|trunk|default|staging|production|stable)(?![\w./-]))[^"\\\s]+
  - |-
    \\?"base\\?"\s*:\s*\\?"(?!(?:main|master|develop|development|dev|trunk|default|staging|production|stable)(?![\w./-]))[^"\\\s]+[\s\S]*?\\?"op\\?"\s*:\s*\\?"pr_create\\?"
scope: ["tool:bash", "tool:github"]
interruptMode: never
---

This PR targets a branch that is not a default branch, so it is one layer of a stack. Do not
describe the stack in the PR body. Link the PRs as a native GitHub stack, bottom to top, as
described in `references/stacks.md` of the `github` skill:

```bash
gh pr view <number> --json number,baseRefName,headRefName,state   # check each base/head chain first
gh stack link --remote origin <bottom-pr> <next-pr> ... <top-pr>
```

Exit code 9 means the repository has no stacked PRs enabled, so do not claim the PRs are linked.
