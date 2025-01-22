{ pkgs, inputs, ... }:

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

  # TODO fix ls colors
  programs.zsh = {
    enable = true;

    autosuggestion.enable = false;
    enableCompletion = true;
    enableVteIntegration = true;

    initExtra = ''
      export CLICOLOR=1
      autoload -Uz colors && colors

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
    '';

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
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = inputs.zsh-nix-shell;
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
