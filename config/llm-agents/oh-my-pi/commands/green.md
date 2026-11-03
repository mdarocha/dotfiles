---
description: Make the current branch's PR green: CI passing and every review thread handled
---

<critical>
MUST continue until CI for the latest pushed HEAD is green and no review thread is left without a reply.
NEVER stop after one fix attempt.
</critical>

Follow the "Getting a PR green" section of the `github` skill. Use its scripts: `ci-wait.sh` to wait for checks, `ci-failures.sh` for failure logs, and `pr-threads.sh` to list, reply to, and resolve review threads. A `github` tool `run_watch` may replace `ci-wait.sh` when that tool is available.

Per iteration:
1. Wait for checks on the pushed head.
2. On failure, fix the cause, commit, and push.
3. List review threads and handle each one: fix or explain, push, reply, then resolve threads that have a reply.
4. Return to step 1 for the new head.

Complete only when CI for the latest HEAD passes, and every thread is resolved or has a reply stating why it stays open.
