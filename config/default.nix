{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./git
    ./pass
    ./nixgl
    ./zsh
  ];

  targets.genericLinux.enable = true;

  home = {
    username = mkDefault "marek";
    homeDirectory = mkDefault "/home/marek";

    stateVersion = "24.05";

    sessionVariables = {
      # synchronize NIX_PATH with the dotfiles' nixpkgs
      NIX_PATH = "nixpkgs=${inputs.nixpkgs}";

      # make sure libs from nixpkgs can be found
      LD_LIBRARY_PATH = "$HOME/.nix-profile/lib:\${LD_LIBRARY_PATH:-}";
    };
  };

  # shutup home-manager notifications
  news.display = "silent";

  # needed for program icons to show up in DE
  programs.bash.enable = true;
  xdg.enable = true;
  xdg.mime.enable = true;

  # enable man pages for hm-installed packages
  programs.man = {
    enable = true;
    generateCaches = true;
  };

  home.enableNixpkgsReleaseCheck = false;

  # additional packages
  home.packages = with pkgs; [
    devenv
    gh
  ];
}
