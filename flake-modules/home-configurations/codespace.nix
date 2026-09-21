{
  mdarocha = {
    zsh.autoDirectenvAllow = true;
    llm-agents.enabledAgents = [
      "copilot"
      "omp"
    ];
  };

  home = {
    username = "codespace";
    homeDirectory = "/home/codespace";

    # required, otherwise the "nix" binary cannot be found in $PATH
    sessionVariablesExtra = ''
      unset __ETC_PROFILE_NIX_SOURCED
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    '';
  };

  programs = {
    man.enable = false; # saves some space
    git.enable = false; # we leave the default codespace git config intact
  };
}
