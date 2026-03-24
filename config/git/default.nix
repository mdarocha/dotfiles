{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) mkDefault mkOption types;
in
{
  options.programs.git.forceSSH = mkOption {
    type = types.bool;
    default = true;
    description = "Force SSH for GitHub and GitLab repositories";
  };

  config.programs.git = {
    enable = lib.mkDefault true;
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

      signing.format = "openpgp";

      url = {
        # always use ssh for Github repos
        "ssh://git@github.com/" = lib.mkIf config.programs.git.forceSSH {
          insteadOf = "https://github.com/";
          pushInsteadOf = "https://github.com/";
        };
        # same for gitlab
        "ssh://git@gitlab.com/" = lib.mkIf config.programs.git.forceSSH {
          insteadOf = "https://gitlab.com/";
          pushInsteadOf = "https://gitlab.com/";
        };
      };

      # ghq tool config
      ghq = {
        root = "~/Projekty";
      };
    };

    # include a machine-local config if available
    includes = [
      { path = "~/.config/git/config.local"; }
    ];
  };

  config.home.packages = [ pkgs.ghq ];
}
