---
name: pr-fixes-one-per-line
description: "Each auto-closed issue must have its own keyword+number line in the PR body"
condition: "(Fixes|Closes|Resolves|Close|Fix|Resolve) #\\d+[,&]| #\\d+.*and.*#\\d+"
scope: ["tool:bash", "tool:github"]
---

When a PR closes multiple issues, each keyword+number pair must be on its own line:

```
Fixes #259
Fixes #260
```

GitHub recognises these keywords (case-insensitive): `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`.

Never combine them on one line (`Fixes #259 and #260`, `Fixes #259, #260`, `Fixes #259 & #260`) — GitHub only auto-closes an issue when the keyword and number appear together with nothing else between them on the same line.