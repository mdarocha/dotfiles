---
name: gh-cli
description: Use the GitHub CLI (gh) to interact with GitHub. Load when working with issues, pull requests, repositories, code search, Actions, CI status, projects, releases, or gists. Triggers include "create a PR", "open a pull request", "open an issue", "check CI", "list PRs", "merge", "review", "check workflow status", "GitHub Actions", or any task involving GitHub - even if the user doesn't mention "gh" explicitly.
---

# GitHub CLI (gh)

Use the `gh` CLI to interact with GitHub from the command line. Always prefer `gh` over
raw API calls or web browser interaction.

> **Important:** `gh` should already be installed and authenticated. If a command fails due to
> missing installation or authentication, notify the user — do not attempt to install or
> configure `gh` yourself.

## Permissions

Commands are split into two categories based on configured permissions:

**Readonly (run freely):** `list`, `view`, `status`, `checks`, `diff`, `checkout`, `search`,
`watch`, `download`, `browse` — these never modify remote state and can be run without asking.

**Mutating (requires user confirmation):** `create`, `edit`, `close`, `merge`, `comment`,
`review`, `reopen`, `ready`, `rerun`, `cancel`, `delete`, `upload`, `fork`, `sync`, `run`,
`enable`, `disable`, `lock`, `unlock`, `revert`, `update-branch`, `gh api` — these modify
remote state and will prompt the user for approval before executing.

Always prefer running readonly commands first to gather context, then propose mutating
commands and let the user confirm.

## Key Patterns

- Use `--json` and `--jq` for structured data extraction (avoids fragile text parsing)
- Use `--repo owner/repo` to target a different repository
- Use `--paginate` for large result sets
- Avoid interactive commands (`-i` flags, editors) — always pass arguments directly
- This skill covers the most common operations. For additional subcommands not listed here,
  run `gh --help` or `gh <command> --help` to discover available commands and flags

## Pull Requests

```bash
# Readonly — run freely
gh pr list
gh pr list --state all --author @me
gh pr list --json number,title,state --jq '.[] | select(.title | contains("fix"))'
gh pr view 123
gh pr view 123 --comments
gh pr view 123 --json title,body,state,author,commits,files
gh pr checkout 123
gh pr diff 123
gh pr diff 123 --name-only
gh pr checks 123
gh pr checks 123 --watch
gh pr status

# Mutating — user will be asked to confirm
gh pr create --title "Title" --body "Description"
gh pr create --draft --base main --head feature
gh pr create --reviewer user1,user2 --labels enhancement
gh pr create --body-file body.md
gh pr edit 123 --title "New title" --add-label bug --add-reviewer user1
gh pr merge 123 --squash --delete-branch
gh pr close 123 --comment "Reason"
gh pr reopen 123
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "Please fix..."
gh pr comment 123 --body "Comment text"
gh pr ready 123
```

## PR Review Threads

GitHub has no dedicated `gh pr` subcommand for resolving review comment threads.
Use the GraphQL API via `gh api graphql`.

> **Confirmation rule:** Only run the resolve mutation when the user has explicitly
> requested it (e.g. "mark the comment as resolved", "resolve that thread").
> In all other cases — such as when reviewing a PR or summarising feedback —
> list the threads for context but ask for confirmation before resolving anything.

```bash
# Readonly — list review threads with their IDs and resolution state
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 1) { nodes { body } }
        }
      }
    }
  }
}
' -f owner=OWNER -f repo=REPO -F pr=NUMBER

# Mutating — resolve a single thread by its node ID (from the query above)
gh api graphql -f query='
mutation($id: ID!) {
  resolveReviewThread(input: {threadId: $id}) {
    thread { id isResolved }
  }
}
' -f id="PRT_kwDO..."
```

The node ID looks like `PRT_kwDO...` and is returned by the `reviewThreads` query above.
To resolve all unresolved threads in one pass, pipe the query result through `jq` to
extract IDs, then loop and call the mutation for each.

## Issues

```bash
# Readonly — run freely
gh issue list
gh issue list --state all --labels bug
gh issue list --assignee @me
gh issue list --search "is:open label:bug"
gh issue list --json number,title,state
gh issue view 123
gh issue view 123 --comments
gh issue view 123 --json title,body,state,labels
gh issue status

# Mutating — user will be asked to confirm
gh issue create --title "Bug: description" --body "Details..."
gh issue create --title "Bug" --labels bug,high-priority --assignee @me
gh issue edit 123 --title "New title" --add-label enhancement
gh issue close 123 --comment "Fixed in PR #456"
gh issue reopen 123
gh issue comment 123 --body "Comment text"
```

## GitHub Actions / CI

```bash
# Readonly — run freely
gh run list
gh run list --workflow "ci.yml" --branch main --limit 10
gh run view 123456789
gh run view 123456789 --log
gh run view 123456789 --job 987654321
gh run watch 123456789
gh run download 123456789 --name build --dir ./artifacts
gh workflow list
gh workflow view ci.yml --yaml

# Mutating — user will be asked to confirm
gh run rerun 123456789
gh run cancel 123456789
gh workflow run ci.yml --ref develop
```

## Repositories

```bash
# Readonly — run freely
gh repo view
gh repo view owner/repo --json name,description,defaultBranchRef
gh repo clone owner/repo

# Mutating — user will be asked to confirm
gh repo create my-repo --public --description "Description"
gh repo fork owner/repo --clone
gh repo sync
gh repo set-default owner/repo
```

## Search

```bash
# All search commands are readonly — run freely
gh search code "pattern" --repo owner/repo
gh search code "import" --extension py
gh search issues "label:bug state:open"
gh search prs "is:open review:required"
gh search repos "stars:>1000 language:python" --sort stars
```

## API Requests

For operations not covered by dedicated subcommands, use `gh api` directly.
All `gh api` calls require user confirmation since they can modify remote state.

```bash
# REST
gh api /repos/owner/repo --jq '.stargazers_count'
gh api --method POST /repos/owner/repo/issues \
  --field title="Title" --field body="Body"

# GraphQL
gh api graphql -f query='{
  viewer { login repositories(first: 5) { nodes { name } } }
}'

# Pagination
gh api /user/repos --paginate
```

## Releases

```bash
# Readonly — run freely
gh release list
gh release view v1.0.0
gh release download v1.0.0 --pattern "*.tar.gz" --dir ./downloads

# Mutating — user will be asked to confirm
gh release create v1.0.0 --notes "Release notes" --target main
gh release create v1.0.0 --draft --notes-file notes.md
gh release upload v1.0.0 ./artifact.tar.gz
```

## Variables

```bash
# Readonly — run freely
gh variable list
gh variable get MY_VAR

# Mutating — user will be asked to confirm
gh variable set MY_VAR "value"
```

## Common Workflows

### Create PR from Issue

```bash
# Mutating — each step will ask for confirmation
gh issue develop 123 --branch feature/issue-123
# Make changes, commit, push...
gh pr create --title "Fix #123" --body "Closes #123"
```

### Bulk Operations

```bash
# List is readonly, but each close is mutating and will ask
gh issue list --search "label:stale" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --comment "Closing as stale"
```

## Output Formatting

```bash
# JSON with jq filtering
gh pr list --json number,title --jq '.[] | select(.number > 100)'

# Go templates
gh repo view --template '{{.name}}: {{.description}}'
```

For full subcommand reference, run `gh <command> --help`.
