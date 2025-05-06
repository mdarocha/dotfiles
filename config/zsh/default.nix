{ pkgs, lib, inputs, ... }:

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

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
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
