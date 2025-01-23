{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.password-store = {
    enable = lib.mkDefault false;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-audit ]);
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
    };
  };

  # ensure clipboard work
  home.packages = lib.optional config.programs.password-store.enable pkgs.wl-clipboard;
}
