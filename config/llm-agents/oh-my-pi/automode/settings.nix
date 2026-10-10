# Schema: https://github.com/czottmann/pi-automode/blob/main/docs/configuration.md
{
  autoMode = {
    classifierReasoningLevel = "low";

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
    ];

    allow = [
      "$defaults"
      "Running nixpkgs packages ad hoc with `nix run nixpkgs#<pkg>` or `nix shell nixpkgs#<pkg>` to get a missing tool"
      "Building and evaluating Nix expressions (`nix build`, `nix eval`, `nix flake check`, `nix flake lock`)"
      "Committing to the current repository and pushing a task branch; opening or updating a pull request on github.com/mdarocha when the user asked for a PR"
      "Non-GET requests to the trusted providers, package sources, and source control listed in the environment, as part of the task"
      "Modifying, overwriting, or deleting git-tracked files inside the current repository or its worktrees (including `git rm`) when the task requires it, e.g. fixing code or resolving PR review comments; git history keeps this recoverable. Files that are untracked or ignored and predate the session still need explicit user approval"
    ];

    soft_deny = [
      "$defaults"
      "Creating, editing, or deleting files when the user only asked a question or asked for suggestions or a proposal"
      "Removing existing code comments or configuration entries the task did not ask to change"
      "Activating a system or home configuration on this machine (`nixos-rebuild switch`, `home-manager switch`, `nix run .#apply`) without the user asking"
      "Garbage-collecting the Nix store or deleting profile generations (`nix-collect-garbage`, `nix store gc`)"
      "Changing live Home Assistant configuration (automations, dashboards, energy settings) without the user asking"
      "Merging pull requests, closing issues, or publishing packages and releases"
    ];

    hard_deny = [
      "$defaults"
      "Reading secrets from the desktop keyring or Secret Service (secret-tool, gnome-keyring, kwallet) or browser credential stores"
      "Printing or sending authentication tokens (`gh auth token`, provider API keys, cloud credentials) outside the tool that owns them"
    ];

    deniedPaths = [
      "~/.ssh/*"
      "~/.gnupg/*"
      "~/.password-store/*"
      "~/.local/share/keyrings/*"
      "~/.config/gh/hosts.yml"
      "~/.git-credentials"
      "~/.netrc"
      "~/.aws/*"
      "~/.azure/*"
      "~/.kube/*"
      "~/.docker/config.json"
      "~/.config/rclone/*"
      "~/.claude/.credentials.json"
      "~/.omp/agent/agent.db*"
      "~/.mozilla/*"
      "~/.config/chromium/*"
      "~/.config/google-chrome/*"
    ];
  };

  permissions = {
    ask = [
      "bash(sudo *)"
      "bash(git push -f*)"
      "bash(git push * -f*)"
      "bash(git push *--force*)"
      "bash(gh pr merge*)"
      "bash(nix-collect-garbage*)"
      "bash(nix store gc*)"
    ];

    # Side-effect-free OMP tools that would otherwise each cost a classifier call.
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
    ];
  };
}
