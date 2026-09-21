{
  mdarocha = {
    llm-agents = {
      enabledAgents = [ "claude" ];
      claude-code.package = null;
    };
    zsh.autoDirenvAllow = true;
  };

  home = {
    username = "root";
    homeDirectory = "/root";

    # required, otherwise the "nix" binary cannot be found in $PATH
    sessionVariablesExtra = ''
      unset __ETC_PROFILE_NIX_SOURCED
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    '';
  };

  programs.man.enable = false; # saves some space
}
