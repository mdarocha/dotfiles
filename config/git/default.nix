{ lib, ... }:

let
  inherit (lib) mkDefault;
in
{
  programs.git = {
    enable = lib.mkDefault true;
    ignores = [ ".ccls-cache" ];
    lfs.enable = true;

    userName = mkDefault "mdarocha";
    userEmail = mkDefault "git@mdarocha.pl";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
  };
}
