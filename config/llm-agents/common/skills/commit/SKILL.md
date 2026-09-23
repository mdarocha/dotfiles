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

## Inspect and stage

Check the recent commit style, working-tree state, unstaged diff, and staged diff before committing. Match the repository’s established message style.

Stage only files and hunks attributable to this session:

```bash
git add <session-file>...
```

For a file mixed with unrelated edits, use `git add -p <file>` and select only the session’s hunks. If unrelated content is already staged, prepare the session commit from an isolated index; if that cannot be done safely, stop and ask before committing. Never run a bare commit that would include unrelated staged work.

Review the resulting staged diff before committing:

```bash
git diff --cached --stat
git diff --cached
```

## Commit

Use one short, specific, single-line message in the repository’s style. If no style is clear, use a lowercase imperative message without a trailing period or attribution trailers.

```bash
git commit -m "<message>"
```

Do not create follow-up commits or push the branch.
