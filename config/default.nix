{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./git
    ./ghostty
    ./llm-agents
    ./vscode
    ./zsh
    ./zed
    ../overlays/hm
  ];

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };

  home.stateVersion = "24.05";

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  systemd.user.sessionVariables = {
    # synchronize NIX_PATH with the dotfiles' nixpkgs (for <nixpkgs> angle-bracket lookups)
    NIX_PATH = lib.mkForce "nixpkgs=${inputs.nixpkgs}";

    LD_LIBRARY_PATH = "$HOME/.nix-profile/lib:\${LD_LIBRARY_PATH:-}";
  };

  news.display = "silent";

  # needed for program icons to show up in DE
  programs.bash.enable = true;
  xdg.enable = true;
  xdg.mime.enable = true;

  programs.man = {
    enable = lib.mkDefault true;
    generateCaches = lib.mkDefault true;
  };

  home.enableNixpkgsReleaseCheck = false;

  home.packages = [
    pkgs.devenv
    pkgs.cachix

    pkgs.jq
    # needed for zed
    pkgs.nil
  ];
}
