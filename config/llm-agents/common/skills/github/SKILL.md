---
name: github
description: Work with GitHub repositories, issues, pull requests, attachments, issue artifacts, reviews, Actions, and stacked PRs. Use for GitHub resources, CI checks, `gh` commands, or requests to create, link, update, sync, or merge a PR stack.
user-invocable: false
---

# GitHub

Prefer a session's structured GitHub tool for supported operations; use `gh` for gaps such as review-thread mutations, releases, and `gh stack`. Use `gh` rather than raw HTTP or browser automation for CLI-supported operations. Read existing state before changing it. A request to create or link PRs authorizes those actions, not a merge; follow the session's permission policy for other remote changes. Do not assume a command will prompt for approval.

For `gh pr`, `gh issue`, and other supported commands, use `--repo owner/repo` outside the checkout or when targeting another repository; `gh stack` operates in the current checkout. Use `--json`/`--jq` for structured output and `--paginate` when the first page is insufficient. Avoid interactive selectors and editors in agent runs. `gh <command> --help` is the source for flags not covered here.

## Pull requests and issues

```bash
gh pr list --json number,title,baseRefName,headRefName,state
gh pr view 123 --json title,body,state,files,commits
gh pr diff 123
gh pr checks 123
gh pr create --base main --head feature --title "Title" --body "Description"
gh pr edit 123 --add-reviewer user1
gh pr review 123 --request-changes --body "Requested change"

gh issue list --state open --json number,title,labels
gh issue view 123 --comments
gh issue create --title "Bug" --body "Reproduction and expected behavior"
```

Honor the repository's worktree/branch convention when checking out a PR; don't replace the user's working tree merely to read it. For code search, use the available code-search tool; `gh search code "term" --repo owner/repo` also finds code in repositories accessible to your GitHub account.

### Images and videos

The dotfiles-managed `gh` supports `--attach` on `gh issue create/edit/comment`, `gh pr create/edit/comment`, and `gh issue artifact create/edit`. Use it to upload images or videos directly to a body or comment; repeat the flag for multiple files (up to 50 per command). It does not accept arbitrary file types; Markdown and HTML files go on an issue as artifacts.

```bash
gh issue create --title "Login fails" --body 'Screenshot: ![error state](./login.png)' --attach ./login.png
gh issue edit 123 --attach './after.png#Updated login screen'
gh pr comment 123 --body "Before and after" --attach ./before.png --attach ./after.png
```

An attached file referenced in the body as `![alt](./login.png)` is rewritten to its uploaded URL and retains that alt text; otherwise the image or video is appended. Use `--attach './login.png#Descriptive alt text'` for an unreferenced image (the filename is the default alt text). Videos render as players and do not take alt text. `edit --attach` without `--body`/`--body-file` preserves the existing body and appends the asset; attach to one issue or PR at a time. On a partial upload failure, create/edit may still succeed remotely and print the URL while exiting nonzero: inspect the resource before retrying to avoid duplicates.

### Issue artifacts

`gh issue artifact` (preview) attaches Markdown documents, HTML documents, and links to an issue. Read `references/artifacts.md` before creating, editing, listing, or deleting artifacts.

### Reviews

Copilot review requests and effort are in `references/reviews.md`. Review threads are handled by `scripts/pr-threads.sh` (see "Getting a PR green").

## Getting a PR green

Green means two things: the latest CI run for the pushed head passes, and every review thread is answered and either resolved or left open with a stated reason. Repeat until neither has open items.

1. Wait for CI: `scripts/ci-wait.sh --pr 123`. Exit 0 means all checks passed; 1 means a check failed and the script prints the failure excerpt; 2 means timeout; 3 means no checks appeared. Its default timeout is 1800 s, so give the tool call a longer timeout or run it in the background. A `github` tool `run_watch` can replace it, but it watches only Actions runs, so checks and statuses from other apps go unseen. When its result says `Log tail unavailable` (gh refuses logs that contain escape sequences), get the log with `scripts/ci-failures.sh <run-id>`.
2. On failure, fix the cause, verify locally when that is cheaper than another push, commit, and push.
3. List review threads: `scripts/pr-threads.sh list 123`. It prints unresolved threads with every comment and the non-empty review summaries; `--all` includes resolved and outdated threads. Each thread header shows its ID. A `pr://123` read shows review comments too, but without thread IDs or resolved state, and with the whole PR body.
4. For each thread, read the full comment, then either fix the code or decide not to change it. Push the fix first, so the reply can cite a commit that exists.
5. Reply with the commit short SHA and what changed, or with the reason for not changing: `scripts/pr-threads.sh reply PRRT_ID "text"`.
6. Resolve only threads that have a reply: `scripts/pr-threads.sh resolve PRRT_ID [PRRT_ID...]`. Leave a thread open when the reviewer should decide.
7. A review summary with no thread needs a PR comment, not a thread reply: `gh pr comment 123 --body "..."`.
8. Return to step 1 for the new head.

Bot reviewers, including Copilot, post threads the same way.

## Stacked pull requests

Read `references/stacks.md` before creating, linking, or merging a stack. It covers the `gh stack` commands, the bottom-to-top linking rule, and exit codes. Stacks are a public preview: check `gh stack <subcommand> --help` before relying on a flag.

## Actions and other operations

```bash
gh run list --workflow ci.yml --branch main --limit 10
gh run view 123456789 --log-failed
gh workflow view ci.yml --yaml
gh release view v1.0.0
gh api /repos/owner/repo --jq '.default_branch'
```

Use `gh api` for operations missing from native tools and `gh` subcommands; GET and GraphQL queries read state, while POST/PATCH/DELETE and GraphQL mutations change it. Don't classify every `gh api` call as mutating.

`scripts/ci-failures.sh` (in this skill's directory) prints failed jobs and steps with log prefixes stripped, so it is shorter than raw `gh run view --log-failed`. Pass a PR (`--pr 123`), a run ID (`123456789 -n 80`), or nothing for the latest failed run on the current branch. `gh pr checks` exits 8 while checks are pending; the script treats that as normal.
