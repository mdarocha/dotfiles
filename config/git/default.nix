{
  config,
  lib,
  pkgs,
  ...
}:

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
      user.name = lib.mkDefault "mdarocha";
      user.email = lib.mkDefault "git@mdarocha.pl";

      # mostly based on https://jvns.ca/blog/2024/02/16/popular-git-config-options
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      commit.verbose = true;
      rerere.enable = true;
      diff.algorithm = "histogram";

      ghq = {
        root = lib.mkDefault "~/Projekty";
      };
    }
    // lib.optionalAttrs (config.programs.gh.enable && config.programs.gh.gitCredentialHelper.enable) {
      # gh's credential helper only ever handles HTTPS auth; rewrite SSH
      # remotes to HTTPS so `git push`/`fetch` work through it instead.
      url."https://github.com/".insteadOf = "git@github.com:";
    };

    # include a machine-local config if available
    includes = [
      { path = "~/.config/git/config.local"; }
    ];
  };

  config.home.packages = [ pkgs.ghq ];
}
