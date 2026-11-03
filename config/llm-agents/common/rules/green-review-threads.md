---
name: green-review-threads
description: "Getting a PR green also covers its review threads"
condition:
  - "\"op\"\\s*:\\s*\"run_watch\""
  - "ci-wait\\.sh"
scope: ["tool:github", "tool:bash"]
interruptMode: never
---

When this CI watch is part of getting a PR green (for example `/green`), also handle the PR's review threads as described in the "Getting a PR green" section of the `github` skill: list them with `scripts/pr-threads.sh list <pr>`, fix or explain each one, push, reply, then resolve the threads that have a reply. The PR is green only when CI passes for the latest HEAD and no thread is left without a reply.
