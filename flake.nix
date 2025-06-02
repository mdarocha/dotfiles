{
  description = "personal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-config = {
      url = "github:mdarocha/neovim-config";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zsh plugins
    oh-my-zsh = {
      url = "github:ohmyzsh/ohmyzsh/master";
      flake = false;
    };

    zsh-vanilli = {
      url = "github:yous/vanilli.sh/master";
      flake = false;
    };

    zsh-windows-title = {
      url = "github:mdarocha/zsh-windows-title/master";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      neovim-config,
      nixgl,
      ...
    }:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          shellcheck =
            let
              inherit (pkgs.lib.fileset) toSource unions;
            in
            pkgs.testers.shellcheck {
              name = "shellcheck";
              src = toSource {
                root = ./.;
                fileset = unions [
                  ./install.sh
                  ./scripts/lib.sh
                  ./scripts/nix-daemon.initd
                ];
              };
            };

          homeConfigurations =
            let
              inherit (pkgs.lib) attrValues map;
              paths = map (config: config.activationPackage) (attrValues self.homeConfigurations);
            in
            pkgs.symlinkJoin {
              name = "home-configurations";
              inherit paths;
            };

          apps =
            let
              inherit (pkgs.lib) attrValues concatMapStringsSep;
              paths = concatMapStringsSep "\n" (app: app.program) (attrValues self.apps.x86_64-linux);
            in
            pkgs.writeText "apps-check" paths;
        };

      apps.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          inherit (pkgs.lib) attrsToList concatMapStringsSep;
        in
        {
          report-sizes =
            let
              configurations = concatMapStringsSep "\n" (config: ''
                echo "| \`${config.name}\` | $(
                  nix path-info --json --closure-size ${config.value.activationPackage} \
                    | jq -r 'to_entries | first | .value.closureSize' | numfmt --to=si --suffix=B
                ) |"
              '') (attrsToList self.homeConfigurations);
              script = pkgs.writeShellApplication {
                name = "report";
                text = ''
                  echo "# homeConfigurations sizes"

                  echo "| Configuration | Size |"
                  echo "| :-- | :-- |"
                  ${configurations}
                '';
              };
            in
            {
              type = "app";
              program = "${script}/bin/report";
            };
          apply =
            let
              configurations = concatMapStringsSep "\n" (
                config: "configurations['${config.name}']=${config.value.activationPackage}"
              ) (attrsToList self.homeConfigurations);

              script = pkgs.writeShellApplication {
                name = "apply";
                text = ''
                  # shellcheck disable=SC1091
                  source "${./scripts/lib.sh}";

                  declare -A configurations
                  ${configurations}

                  echo "⚙️  Applying new configuration for $CONFIGURATION..."
                  export HOME_MANAGER_BACKUP_EXT="backup"
                  "''${configurations[$CONFIGURATION]}/activate"

                  # TODO removed due to issues found with gcroots
                  #echo "🧹 Cleaning up..."
                  #nix-collect-garbage -d
                '';
              };
            in
            {
              type = "app";
              program = "${script}/bin/apply";
            };
        };
      homeConfigurations =
        let
          inherit (home-manager.lib) homeManagerConfiguration;
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [ nixgl.overlay ];
          };

          mkHomeManagerConfiguration =
            additionalConfig:
            homeManagerConfiguration {
              extraSpecialArgs = { inherit inputs; };
              inherit pkgs;

              modules = [
                neovim-config.homeManagerModules.default
                ./config
                (
                  { lib, ... }:
                  let
                    inherit (lib) mkDefault;
                  in
                  {
                    mdarocha = {
                      autoupdate.enable = mkDefault false;
                      nixgl.enable = mkDefault false;

                      neovim.enable = mkDefault true;
                    };

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
          linux = mkHomeManagerConfiguration {
            mdarocha = {
              autoupdate.enable = true;
              nixgl.enable = true;
            };
          };

          wsl = mkHomeManagerConfiguration { };

          codespace = mkHomeManagerConfiguration {
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
        };
    };
}
