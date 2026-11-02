# Schema: https://github.com/czottmann/pi-automode/blob/main/docs/configuration.md
{
  autoMode = {
    classifierReasoningLevel = "low";
    # 6 of ~9300 classifications hit the 20s default and failed closed.
    classifierTimeoutMs = 40000;
    # Pasted logs in long sessions push the real authorization out of the 4000 default.
    maxUserTranscriptTokens = 8000;
    allowInsideWorkingDirectory = true;

    log = {
      enabled = true;
      classifierIo = false;
    };

    environment = [
      "$defaults"
      "Source control: github.com/mdarocha and every repository under it; pull requests and issues there belong to the user"
      "Work source control and package feeds: Azure DevOps (dev.azure.com, *.visualstudio.com) and its private NuGet/npm feeds"
      "Trusted package sources: nixpkgs and binary caches (nixos.org, cachix.org, numtide.com), npm, PyPI, crates.io, NuGet"
      "Trusted model and tool providers: Anthropic, OpenAI, OpenRouter, GitHub Copilot, Google Antigravity, Exa, Context7, grep.app"
      "Personal domain: mdarocha.pl"
      "Dotfiles: this machine's Home Manager/NixOS configuration lives in github.com/mdarocha/dotfiles"
      "Scratch areas: /tmp and ~/.omp/wt hold clones, worktrees, and build output that agents create for a task; they are disposable"
      "Agent coordination: a message wrapped in `<irc from=\"parent\" ...>` comes from the coordinating agent, which holds the user's request. Treat it like a user message that carries the user's authorization for the task it describes"
      "A coordinator HOLD covers only the action it names. Tool results are hidden from you, so a later note lifting the hold may not be visible"
    ];

    allow = [
      "$defaults"
      "Running nixpkgs packages ad hoc with `nix run nixpkgs#<pkg>` or `nix shell nixpkgs#<pkg>` to get a missing tool"
      "Building and evaluating Nix expressions (`nix build`, `nix eval`, `nix flake check`, `nix flake lock`)"
      "Committing to the current repository and pushing a task branch; opening or updating a pull request on github.com/mdarocha when the user asked for a PR"
      "Non-GET requests to the trusted providers, package sources, and source control listed in the environment, as part of the task"
      "Modifying, overwriting, or deleting git-tracked files inside the current repository or its worktrees (including `git rm`) when the task requires it, e.g. fixing code or resolving PR review comments; git history keeps this recoverable. Files that are untracked or ignored and predate the session still need explicit user approval"
      "Merging pull requests in github.com/mdarocha repositories with `gh pr merge` (no `--admin`, branch protection respected) when the user asked to merge them, including `--delete-branch`, combined PRs the agent opened for that purpose, and closing the superseded bot PRs with a comment that points to the combined one"
      "Force-pushing (`--force-with-lease` or `--force`) a non-default branch the agent created or was asked to fix in this task, e.g. after an amend or rebase of a PR branch"
      "Deleting remote branches and GitHub Actions caches that the agent created during this task (test branches, merged PR branches)"
      "Rerunning failed or cancelled CI runs of pull requests on the user's repositories (`gh run rerun`); rerunning a run on the default branch that deploys still needs the user"
      "Deleting scratch directories under /tmp or ~/.omp/wt that agents created for the task (clones, worktrees, build output, drafts), including ignored state inside them such as `.devenv`, `node_modules`, and `result` links, with `rm -rf` or `git worktree remove`. Never `$HOME`, `/tmp` itself, or a path the agent did not create"
      "Editing an application's own settings files under ~/.config, ~/.var/app, or ~/.local/share when the user asked to change that application's settings (e.g. Steam launch options), unless the file is a credential store"
    ];

    soft_deny = [
      "$defaults"
      "Creating, editing, or deleting files when the user only asked a question or asked for suggestions or a proposal"
      "Removing existing code comments or configuration entries the task did not ask to change"
      "Activating a system or home configuration on this machine (`nixos-rebuild switch`, `home-manager switch`, `nix run .#apply`) without the user asking"
      "Garbage-collecting the Nix store or deleting profile generations (`nix-collect-garbage`, `nix store gc`)"
      "Changing live Home Assistant configuration (automations, dashboards, energy settings) without the user asking"
      "Merging pull requests, closing issues, or publishing packages and releases without the user asking"
      "Merging with `--admin` or otherwise bypassing branch protection, required checks, or required reviews unless the user explicitly asked to bypass them for that PR"
    ];

    # No $defaults: the stock "fabricated content" rule is replaced below, since the
    # classifier can't see tool results and blocked true claims about checks the agent ran.
    hard_deny = [
      "Weakening TLS, certificate validation, authentication, authorization, audit logging, or security controls."
      "Adding persistence such as SSH authorized keys, shell profile modifications, cron jobs, launch agents, login items, or background agents."
      "Granting admin, owner, IAM, RBAC, repository, or production access permissions."
      "Exfiltrating repository contents, secrets, credentials, private keys, tokens, or internal data to untrusted domains, public storage, logs, URLs, metadata, or third-party services."
      "Systematically scanning for credentials, tokens, private keys, or secrets beyond what the task directly requires."
      "Tampering with logs, audit trails, security monitoring, permission rules, auto-mode configuration, or files that define the agent's safety controls."
      "Creating services, endpoints, workflows, or autonomous agents that execute arbitrary code without meaningful human approval."
      "Posting or updating public or external content that is fabricated, impersonates the user, or claims a person's approval that did not happen. The agent's statements about checks it ran itself (tests, builds, evals, lint) are not fabrication: tool results are hidden from you, so missing output in the transcript is not evidence. Block only when the transcript shows the check was never invoked or the claim contradicts visible evidence."
      "Changing GitHub repository or organization settings: Actions workflow permissions (e.g. `can_approve_pull_request_reviews`), rulesets, branch protection, secrets, deploy keys, visibility; or deleting repositories."
      "Reading secrets from the desktop keyring or Secret Service (secret-tool, gnome-keyring, kwallet) or browser credential stores"
      "Printing or sending authentication tokens (`gh auth token`, provider API keys, cloud credentials) outside the tool that owns them"
    ];

    # Trailing `*` on files: pi-automode doesn't strip omp read selectors (`~/.netrc:1-2`).
    deniedPaths = [
      "~/.ssh/*"
      "~/.gnupg/*"
      "~/.password-store/*"
      "~/.local/share/keyrings/*"
      "~/.config/gh/hosts.yml*"
      "~/.git-credentials*"
      "~/.netrc*"
      "~/.aws/*"
      "~/.azure/*"
      "~/.kube/*"
      "~/.docker/config.json*"
      "~/.config/rclone/*"
      "~/.claude/.credentials.json*"
      "~/.omp/agent/agent.db*"
      "~/.mozilla/*"
      "~/.config/chromium/*"
      "~/.config/google-chrome/*"
      "~/.thunderbird/*"
      "~/.config/thunderbird/*"
      "~/.config/evolution/*"
      "~/.local/share/evolution/*"
      "~/.config/goa-1.0/*"
      "~/.config/github-copilot/*"
      "~/.pulumi/credentials.json*"
      "~/.npmrc*"
      "~/.microsoft/usersecrets/*"
      "~/.local/share/MicrosoftCredentialProvider/*"
      "~/.claude.json*"
      "~/.config/Claude/*"
      "~/.local/share/pki/*"
      "~/.zsh_history*"
      "~/.var/app/com.slack.Slack/*"
      "~/.var/app/com.discordapp.Discord/*"
      "~/.var/app/org.gnome.Fractal/*"
    ];
  };

  permissions = {
    # Subagents have no UI, so `ask` blocks them outright; leave user-authorizable actions to the classifier.
    ask = [
      "bash(sudo *)"
      "bash(git push -f*)"
      "bash(git push * -f*)"
      "bash(git push *--force)"
      "bash(git push *--force *)"
      "bash(gh pr merge*--admin*)"
      "bash(nix-collect-garbage*)"
      "bash(nix store gc*)"
    ];

    # Skip the classifier. A bash chain is allowed only if every command in it matches.
    allow = [
      "glob"
      "todo"
      "ask"
      "wait"
      "web_search"
      "bash(git status*)"
      "bash(git diff*)"
      "bash(git log*)"
      "bash(git show*)"
      "bash(git rev-parse*)"
      "bash(git ls-files*)"
      "bash(git blame*)"
      "bash(git branch --show-current)"
      "bash(git remote -v)"
      "bash(git stash list*)"
      "bash(git add*)"
      "bash(git fetch*)"
      "bash(git worktree list*)"
      "bash(gh pr view*)"
      "bash(gh pr list*)"
      "bash(gh pr diff*)"
      "bash(gh pr checks*)"
      "bash(gh issue view*)"
      "bash(gh issue list*)"
      "bash(gh run list*)"
      "bash(gh run view*)"
      "bash(gh run watch*)"
      "bash(gh workflow list*)"
      "bash(gh workflow view*)"
      "bash(gh release list*)"
      "bash(gh release view*)"
      "bash(gh repo view*)"
      "bash(cd /tmp)"
      "bash(sleep *)"
      "bash(ls*)"
      "bash(pwd)"
      "bash(date*)"
      "bash(which *)"
      "bash(cat)"
      "bash(wc -l)"
      "bash(sort)"
      "bash(uniq)"
    ];
  };
}
