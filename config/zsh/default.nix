{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

{
  imports = [ ./nix-index ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      : ''${XDG_CACHE_HOME:=$HOME/.cache}
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
          echo "''${direnv_layout_dirs[$PWD]:=$(
              echo -n "$XDG_CACHE_HOME"/direnv/layouts/
              echo -n "$PWD" | sha256sum | cut -d ' ' -f 1
          )}"
      }
    '';
  };

  programs.zsh = {
    enable = true;

    autosuggestion.enable = false;
    enableCompletion = true;
    enableVteIntegration = true;

    dotDir = config.home.homeDirectory;

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # Auto-allow direnv for repos owned by the current GitHub user.
        # Used in ephemeral environments (Codespaces, Claude Code) where
        # trust is already implied by the session setup.
        _auto_direnv_allow() {
          [ -f .envrc ] || return 0
          local remote_url owner trusted_user
          remote_url=$(git config --get remote.origin.url 2>/dev/null || true)
          [ -n "$remote_url" ] || return 0
          owner=$(echo "$remote_url" | sed -E 's|.*(github\.com)[:/]([^/]+)/.*|\2|')
          [ -n "$owner" ] || return 0
          trusted_user="''${GITHUB_USER:-}"
          if [ -z "$trusted_user" ] && command -v gh >/dev/null 2>&1; then
            trusted_user=$(gh api user --jq .login 2>/dev/null || true)
          fi
          [ -n "$trusted_user" ] || return 0
          if [ "$owner" = "$trusted_user" ]; then
            direnv allow .
          fi
        }

        if [[ "''${CODESPACES:-}" == "true" ]]; then
          # This file contains logic to cd to the project directory on login
          . /etc/profile.d/codespaces.sh

          # Setup env-secrets, even if over ssh
          # By default this logic (contained in /etc/profile.d/codespaces.sh
          # does not execute on ssh sessions.
          while read line
          do
              key=$(echo $line | sed "s/=.*//")
              value=$(echo $line | sed "s/$key=//1")
              decodedValue=$(echo $value | base64 -d)
              export $key="$decodedValue"
          done < /workspaces/.codespaces/shared/.env-secrets

          _auto_direnv_allow
        fi

        if [[ "''${CLAUDECODE:-}" == "1" ]]; then
          _auto_direnv_allow
        fi

        # use zsh in nix shell
        export SHELL=${pkgs.zsh}/bin/zsh
      '')
      (lib.mkOrder 1200 ''
        export CLICOLOR=1
        autoload -Uz colors && colors

        # ls colors
        export LS_COLORS="$(${pkgs.vivid}/bin/vivid generate solarized-dark)"
        alias ls="ls --color=auto"

        zstyle ':completion:*' menu yes no=5 select
        zstyle ':completion:*:*:make:*' tag-order 'targets'
        zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

        # bindkey fixups for Ptyxis terminal
        if [ -n  $PTYXIS_VERSION ]; then
          bindkey '^[[H'  beginning-of-line
          bindkey '^[[F'  end-of-line
          bindkey '^[[3~' delete-char
        fi

        # load machine-specific config if it exists
        if [ -e "$HOME/.zshrc.local" ]; then
          . "$HOME/.zshrc.local"
        fi
      '')
    ];

    plugins = [
      {
        name = "blockline";
        src = pkgs.writeTextFile {
          name = "zsh-blockline";
          text = builtins.readFile ./blockline.plugin.zsh;
          destination = "/blockline.plugin.zsh";
        };
      }
      {
        name = "window-title";
        src = inputs.zsh-windows-title;
      }
      {
        name = "vanilli.sh";
        file = "vanilli.sh";
        src = inputs.zsh-vanilli;
      }
      {
        name = "extract";
        src = "${inputs.oh-my-zsh}/plugins/extract";
      }
      {
        name = "sudo";
        src = "${inputs.oh-my-zsh}/plugins/sudo";
      }
      {
        name = "systemd";
        src = "${inputs.oh-my-zsh}/plugins/systemd";
      }
    ];

    shellAliases = {
      vimr = "vim -c Renamer";
    };
  };

  home.packages = with pkgs; [
    # Programs used by the 'extract' plugin to work with archives
    unzip
    unrar
    p7zip
  ];
}
