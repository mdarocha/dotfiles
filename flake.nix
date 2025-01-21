{
  description = "personal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
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
    };
}
