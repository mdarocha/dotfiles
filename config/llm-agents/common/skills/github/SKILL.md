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

`gh pr` has no review-thread resolution command. Query thread IDs first, then resolve only the requested thread:

```bash
gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){reviewThreads(first:100){nodes{id isResolved comments(first:1){nodes{body}}}}}}}' -f owner=OWNER -f repo=REPO -F pr=NUMBER
gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id isResolved}}}' -f id=PRT_ID
```

For more than 100 review threads, paginate the GraphQL connection rather than assuming the first page is complete.

### Copilot code review

```bash
gh pr edit 123 --add-reviewer "@copilot"
```

The reviewer bot login is `copilot-pull-request-reviewer[bot]`; GraphQL `requestReviewsByLogin` takes it as `botLogins`. Review effort (Lite or Balanced) has no per-request parameter in the REST API, GraphQL schema, or `gh` as of `gh` 2.103.3, so don't guess a field such as `effort_level`. Without one, the effort comes from the requester's settings, so API-triggered reviews use the token owner's personal setting. The `Review effort:` line in the review body shows what actually ran. Recheck `gh pr edit --help` and cli/cli#14188 before claiming otherwise.

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
