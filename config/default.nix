{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./autoupdate
    ./git
    ./nixgl
    ./zsh
  ];

  targets.genericLinux.enable = true;

  home.stateVersion = "24.05";

  systemd.user.sessionVariables = {
    # synchronize NIX_PATH with the dotfiles' nixpkgs
    NIX_PATH = lib.mkForce "nixpkgs=${inputs.nixpkgs}";

    # make sure libs from nixpkgs can be found
    LD_LIBRARY_PATH = "$HOME/.nix-profile/lib:\${LD_LIBRARY_PATH:-}";

    # needed to make sure omnisharp in zed works
    DOTNET_ROOT = "${(pkgs.dotnetCorePackages.combinePackages [
      pkgs.dotnetCorePackages.sdk_8_0
      pkgs.dotnetCorePackages.sdk_9_0
    ]).unwrapped}/share/dotnet";
  };

  # shutup home-manager notifications
  news.display = "silent";

  # needed for program icons to show up in DE
  programs.bash.enable = true;
  xdg.enable = true;
  xdg.mime.enable = true;

  # enable man pages for hm-installed packages
  programs.man = {
    enable = lib.mkDefault true;
    generateCaches = lib.mkDefault true;
  };

  home.enableNixpkgsReleaseCheck = false;

  # additional packages
  home.packages = [
    pkgs.devenv
    pkgs.gh
    pkgs.cachix

    # needed for zed
    pkgs.nil
  ];
}
