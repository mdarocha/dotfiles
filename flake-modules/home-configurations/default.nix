{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager llm-agents;
  inherit (home-manager.lib) homeManagerConfiguration;

  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = [
      llm-agents.overlays.shared-nixpkgs
      (import ../../overlays/omp-bun-fix.nix)
      (import ../../overlays/nixpkgs/default.nix)
    ];
  };

  mkHomeManagerConfiguration =
    additionalConfig:
    homeManagerConfiguration {
      extraSpecialArgs = { inherit inputs; };
      inherit pkgs;

      modules = [
        ../../config
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
    nixos = mkHomeManagerConfiguration (import ./nixos.nix);
    wsl = mkHomeManagerConfiguration (import ./wsl.nix);
    codespace = mkHomeManagerConfiguration (import ./codespace.nix);
    claude = mkHomeManagerConfiguration (import ./claude.nix);
  };
}
