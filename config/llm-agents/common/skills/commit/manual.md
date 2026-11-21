# Manual commit procedure

For harnesses without a dedicated commit tool. Create exactly one local commit with only this session's work. Never push.

## Inspect and stage

Check the recent commit style, working-tree state, unstaged diff, and staged diff before committing. Match the repository's established message style.

Stage only files and hunks attributable to this session:

```bash
git add <session-file>...
```

For a file mixed with unrelated edits, use `git add -p <file>` and select only the session's hunks. If unrelated content is already staged, prepare the session commit from an isolated index; if that cannot be done safely, stop and ask before committing. Never run a bare commit that would include unrelated staged work.

Review the resulting staged diff before committing:

```bash
git diff --cached --stat
git diff --cached
```

## Commit

Use one short, specific, single-line message in the repository's style. If no style is clear, use a lowercase imperative message without a trailing period or attribution trailers.

```bash
git commit -m "<message>"
```

Do not create follow-up commits or push the branch.
