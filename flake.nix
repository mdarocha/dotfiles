{
  description = "personal dotfiles";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://mdarocha-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    agent-sandbox.url = "github:mdarocha/agent-sandbox.nix";

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
      llm-agents,
      agent-sandbox,
      ...
    }:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

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

          "run-packages" =
            let
              homePath =
                (
                  home-manager.lib.homeManagerConfiguration {
                    extraSpecialArgs = { inherit inputs; };
                    pkgs = self.homeConfigurations.linux.pkgs;
                    modules = [
                      ./config
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
                      {
                        mdarocha = {
                          llm-agents = {
                            enable = true;
                            sandbox.enable = false;
                          };
                        };
                      }
                    ];
                  }
                ).config.home.path;
            in
            pkgs.runCommand "run-packages" { } ''
              export HOME="$TMPDIR/home"
              mkdir -p "$HOME"

              for cmd in git zsh gh omp copilot; do
                if [ ! -x "${homePath}/bin/$cmd" ]; then
                  echo "missing executable in Home Manager profile: $cmd" >&2
                  exit 1
                fi

                "${homePath}/bin/$cmd" --version
              done

              touch "$out"
            '';
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
              script = pkgs.writeShellApplication {
                name = "apply";
                text = ''
                  # shellcheck disable=SC1091
                  source "${./scripts/lib.sh}";

                  echo "⚙️  Applying new configuration for $CONFIGURATION..."
                  export HOME_MANAGER_BACKUP_EXT="backup"
                  nix run .#homeConfigurations."$CONFIGURATION".activationPackage

                  echo "🧹 Cleaning up..."
                  nix-collect-garbage -d
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
            overlays = [
              llm-agents.overlays.default
              (import ./overlays/default.nix)
            ];
          };

          mkHomeManagerConfiguration =
            additionalConfig:
            homeManagerConfiguration {
              extraSpecialArgs = { inherit inputs; };
              inherit pkgs;

              modules = [
                ./config
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
          linux = mkHomeManagerConfiguration {
            mdarocha = {
              llm-agents.enable = true;
              #zed.enable = true;
            };
          };

          wsl = mkHomeManagerConfiguration {
            mdarocha.llm-agents.enable = true;
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
            mdarocha.zsh.autoDirectenvAllow = true;

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
    };
}
