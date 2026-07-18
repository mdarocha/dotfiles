{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault;
in
{
  config.programs.gh = {
    enable = lib.mkDefault true;
    # gh credential helper is enabled by default, which
    # sets up git to use `gh auth git-credential` for HTTPS auth
  };

  config.programs.git = {
    enable = lib.mkDefault true;
    signing.format = "openpgp";
    ignores = [
      ".ccls-cache"
    ];
    lfs.enable = true;

    settings = {
      user.name = mkDefault "mdarocha";
      user.email = mkDefault "git@mdarocha.pl";

      # additional settings
      # mostly based on https://jvns.ca/blog/2024/02/16/popular-git-config-options
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      commit.verbose = true;
      rerere.enable = true;
      diff.algorithm = "histogram";

      # ghq tool config
      ghq = {
        root = lib.mkDefault "~/Projekty";
      };
    };

    # include a machine-local config if available
    includes = [
      { path = "~/.config/git/config.local"; }
    ];
  };

  config.home.packages = [ pkgs.ghq ];
}
