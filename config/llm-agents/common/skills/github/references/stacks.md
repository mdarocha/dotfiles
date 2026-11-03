## Stacked pull requests

`gh stack` is provided declaratively by the dotfiles (`config/git/gh.nix`). A stack is a linear dependency chain in one repository: `(main) <- base-change <- dependent-change`. The bottom PR targets `main`; each higher PR targets the branch immediately below it, so its diff contains only its layer. GitHub's stack grouping is **additional** to the base-branch chain. A pair of PRs with correct bases is not necessarily a GitHub stack.

Choose layers by dependency, with a discrete reviewable concern per branch. Create the lower branch before work that depends on it. Keep unrelated changes in separate stacks. Stacks cannot span forks. The feature is in public preview: exit code 9 means the repository does not have stacked PRs enabled, so do not claim the PRs are linked. Check `gh stack <subcommand> --help` if a flag or behavior changes.

### Existing PRs or separately managed worktrees

When PRs already exist, check their head/base chain and link them **bottom to top**. `link` creates or updates GitHub stack membership without creating local stack tracking. It reuses existing PRs but can update their base branches; inspect the chain before running it. With branch arguments, `link` may push branches and create missing PRs (draft unless `--open`).

```bash
gh pr view 240 --json number,baseRefName,headRefName,state
gh pr view 241 --json number,baseRefName,headRefName,state
gh stack link --remote origin 240 241     # main <- PR 240 <- PR 241
gh stack link --remote origin 242 243     # if 242 is a stack ID, append PR 243
```

The example mirrors an existing two-PR chain: linking #240 and #241 creates a GitHub stack; it neither rewrites their commits nor creates local tracking. A number in the first argument position can mean a **stack ID** if one exists, not necessarily a PR number. Verify the returned stack ID and both PRs' bases after linking. Use `gh stack checkout <PR-or-stack-ID>` only if local stack tracking is needed; it fetches and checks out branches, so respect worktree ownership.

### New locally tracked stack

```bash
gh stack init --base main base-change   # adopt an existing branch or create it
git add <base-files> && git commit -m "Add base change"
gh stack add dependent-change           # from the current top branch
git add <dependent-files> && git commit -m "Add dependent change"
gh stack submit --auto --remote origin  # pushes branches; creates draft PRs and stack
# Add --open only when these PRs should be ready for review.
gh stack view --json
```

Use `gh stack init --base main branch-a branch-b` to adopt an existing local chain. Ensure ancestry and change ownership are correct first: stack metadata alone does not reorder commits. Don't use `gh stack init` for a pair of existing PRs when only remote linking is requested. `gh stack view --json` describes the **locally tracked** stack; it cannot inspect a link-only stack from an unrelated checkout.

### Updating and merging

Edit the branch that owns the change. `gh stack rebase --upstack --remote origin` cascades lower-branch edits upward; `gh stack push --remote origin` pushes rewritten branch tips with leases. `gh stack sync --remote origin` fetches, rebases, pushes, and updates PR/stack state. A noninteractive `sync` may exit 0 while reporting `Sync aborted` on divergence: inspect its output and verify before claiming success. On a rebase conflict, resolve and stage files, then `gh stack rebase --continue`; `gh stack rebase --abort` restores the stack. Do not prune branches unless requested.

```bash
gh stack merge 241 --yes --squash     # merges PR 241 and every unmerged PR below it
gh stack merge 242 --yes --squash     # if 242 is a stack ID, merges the entire stack
```

Merge only on request, bottom to top. The selected merge is all-or-nothing unless it enters a merge queue; protections and checks still apply. Use `gh stack merge`, not `gh pr merge`, to merge multiple layers in one operation. Specify the intended merge method rather than relying on the last-used one. `gh stack modify` is an interactive TUI and is unsuitable for noninteractive runs.

See [GitHub's stacked PR overview](https://docs.github.com/en/pull-requests/get-started/about-stacked-prs) and [CLI command reference](https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands) for current behavior.
