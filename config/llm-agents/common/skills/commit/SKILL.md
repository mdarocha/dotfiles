---
name: commit
description: Creates one local commit for the current session when the user explicitly requests it, or autonomously from a linked worktree after a discrete unit of work. It stages only session-related changes and never pushes.
---

# Commit Session Changes

Create exactly one local commit containing only work from the current session. Never push.

## Consent

- An explicit request to commit, save, checkpoint, or snapshot changes authorizes a commit in any checkout. Do not ask again.
- Completion language alone, such as “I’m done” or “wrap up,” does not authorize a commit; ask whether the user wants one.
- An agent may commit without a request only after completing a discrete unit of work in a linked (non-main) worktree. It must not self-initiate a commit from the main checkout.

## Tooling

If the harness provides a dedicated commit tool (for example a selective-commit helper such as an eval `commit` namespace or a `/commit` command that commits only the lines this agent wrote), use it instead of `git add`/`git commit`. It already limits the commit to session changes.

Otherwise follow [manual.md](manual.md).

## Message

Use one short, specific, single-line message in the repository’s style. If no style is clear, use a lowercase imperative message without a trailing period or attribution trailers.
