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

    # mostly based on https://jvns.ca/blog/2024/02/16/popular-git-config-options
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      commit.verbose = true;
      rerere.enable = true;
      diff.algorithm = "histogram";
    };

    # include a machine-local config if available
    includes = [
      { path = "~/.config/git/config.local"; }
    ];
  };
}
