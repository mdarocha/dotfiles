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
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      neovim-config,
      nixgl,
      ...
    }:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      checks.x86_64-linux = {
        shellcheck =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            inherit (pkgs.lib.fileset) toSource unions;
          in
          pkgs.testers.shellcheck {
            src = toSource {
              root = ./.;
              fileset = unions [
                ./install.sh
              ];
            };
          };
      };

      apps.x86_64-linux.apply =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "apply";
            text = ''
              echo "⚙️  Applying new configuration..."
            '';
          };
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

            programs.git.enable = true;
            programs.password-store.enable = true;
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

            programs.git.enable = false; # we configure git manually
            programs.password-store.enable = false;
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

            programs.git.enable = false; # we leave the default codespace git config intact
            programs.password-store.enable = false;
          };
        };
    };
}
