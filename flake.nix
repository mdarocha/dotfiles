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

    zsh-nix-shell = {
      url = "github:chisui/zsh-nix-shell/master";
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

      checks.x86_64-linux = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in {
        shellcheck =
          let
            inherit (pkgs.lib.fileset) toSource unions;
          in
          pkgs.testers.shellcheck {
            src = toSource {
              root = ./.;
              fileset = unions [
                ./install.sh
                ./scripts/lib.sh
              ];
            };
          };

        homeConfigurations = let
          inherit (pkgs.lib) attrValues map;
          paths = map (config: config.activationPackage) (attrValues self.homeConfigurations);
        in pkgs.symlinkJoin {
          name = "home-configurations";
          inherit paths;
        };

        apps = let
          inherit (pkgs.lib) attrValues map;
          paths = map (app: app.program) (attrValues self.apps.x86_64-linux);
        in pkgs.symlinkJoin {
          name = "apps";
          inherit paths;
        };
      };

      apps.x86_64-linux.apply =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          inherit (pkgs.lib) attrsToList concatMapStringsSep;
          configurations = concatMapStringsSep "\n"
            (config: "configurations['${config.name}']=${config.value.activationPackage}")
            (attrsToList self.homeConfigurations);
          script = pkgs.writeShellApplication {
            name = "apply";
            text = ''
              # shellcheck disable=SC1091
              source "${./scripts/lib.sh}";

              declare -A configurations
              ${configurations}

              echo "⚙️  Applying new configuration for $CONFIGURATION..."
              sh "''${configurations[$CONFIGURATION]}/activate"

              echo "🧹 Cleaning up..."
              nix-collect-garbage -d
            '';
          };
        in
        {
          type = "app";
          program = "${script}/bin/apply";
        };

      homeConfigurations =
        let
          inherit (home-manager.lib) homeManagerConfiguration;

          mkHomeManagerConfiguration =
            additionalConfig:
            homeManagerConfiguration {
              pkgs = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
                overlays = [ nixgl.overlay ];
              };

              extraSpecialArgs = { inherit inputs; };

              modules = [
                neovim-config.homeManagerModules.default
                ./config
                additionalConfig
              ];
            };
        in
        {
          linux = mkHomeManagerConfiguration {
            mdarocha = {
              firefox.enable = true;
              nixgl.enable = true;

              neovim.enable = true;
              neovide = {
                enable = true;
                useNixGl = true;
              };
            };

            programs = {
              git.enable = true;
              password-store.enable = true;
            };
          };

          wsl = mkHomeManagerConfiguration {
            mdarocha = {
              firefox.enable = false;
              nixgl.enable = true;

              neovim.enable = true;
              neovide = {
                enable = true;
                useNixGl = true;
              };
            };

            programs = {
              git.enable = false; # we configure git manually
              password-store.enable = false;
            };
          };

          codespace = mkHomeManagerConfiguration {
            mdarocha = {
              firefox.enable = false;
              nixgl.enable = false;

              neovim.enable = true;
              neovide = {
                enable = false;
                useNixGl = false;
              };
            };

            programs = {
              git.enable = false; # we leave the default codespace git config intact
              password-store.enable = false;
            };
          };
        };
    };
}
