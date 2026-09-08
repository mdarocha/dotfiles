{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager llm-agents;
  inherit (home-manager.lib) homeManagerConfiguration;

  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = [
      llm-agents.overlays.shared-nixpkgs
      (import ../overlays)
    ];
  };

  profiles = {
    linux = ../profiles/linux.nix;
    wsl = ../profiles/wsl.nix;
    deck = ../profiles/deck.nix;
    codespace = ../profiles/codespace.nix;
    claude = ../profiles/claude.nix;
    nixos = ../profiles/nixos.nix;
  };

  mkHomeManagerConfiguration =
    profile:
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
        profile
      ];
    };
in
{
  flake.homeConfigurations = builtins.mapAttrs (_: mkHomeManagerConfiguration) profiles;
}
