{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager llm-agents;
  inherit (home-manager.lib) homeManagerConfiguration;

  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = [
      llm-agents.overlays.shared-nixpkgs
      (import ../overlays/pkgs/default.nix { inherit inputs; })
    ];
  };

  mkHomeManagerConfiguration =
    additionalConfig:
    homeManagerConfiguration {
      extraSpecialArgs = { inherit inputs; };
      inherit pkgs;

      modules = [
        ../config
        (
          { lib, ... }:
          let
            inherit (lib) mkDefault;
          in
          {
            home = {
              username = mkDefault "marek";
              homeDirectory = mkDefault "/home/marek";
            };
          }
        )
        additionalConfig
      ];
    };
in
{
  flake.homeConfigurations = {
    linux = mkHomeManagerConfiguration {
      mdarocha = {
        llm-agents.enable = true;
        zed.enable = true;
      };
    };

    wsl = mkHomeManagerConfiguration {
      mdarocha = {
        llm-agents.enable = true;
        zed = {
          enable = true;
          configDir = "/mnt/c/Users/marek.darocha/AppData/Roaming/Zed";
        };
      };
    };

    deck = mkHomeManagerConfiguration {
      mdarocha = {
        llm-agents.enable = true;
        zed.enable = true;
      };

      programs.git.settings.ghq.root = "~/sdcard/projects";

      # ensure flatpak-installed app icons and .desktop files are visible
      # to plasmashell (systemd user session doesn't source /etc/profile.d/flatpak.sh)
      xdg.systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "\${HOME}/.local/share/flatpak/exports/share"
      ];

      home = {
        username = "deck";
        homeDirectory = "/home/deck";
      };
    };

    codespace = mkHomeManagerConfiguration {
      mdarocha.vscode.enable = true;
      mdarocha.zsh.autoDirectenvAllow = true;

      home = {
        username = "codespace";
        homeDirectory = "/home/codespace";

        # required, otherwise the "nix" binary cannot be found in $PATH
        sessionVariablesExtra = ''
          unset __ETC_PROFILE_NIX_SOURCED
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        '';
      };

      programs = {
        man.enable = false; # saves some space
        git.enable = false; # we leave the default codespace git config intact
      };
    };

    claude = mkHomeManagerConfiguration {
      mdarocha = {
        llm-agents.claude-code-web.enable = true;
        zsh.autoDirectenvAllow = true;
      };

      home = {
        username = "root";
        homeDirectory = "/root";

        # required, otherwise the "nix" binary cannot be found in $PATH
        sessionVariablesExtra = ''
          unset __ETC_PROFILE_NIX_SOURCED
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        '';
      };

      programs.man.enable = false; # saves some space
    };
  };
}
