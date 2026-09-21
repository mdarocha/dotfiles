{
  home = {
    username = "mdarocha";
    homeDirectory = "/home/mdarocha";
  };

  mdarocha.llm-agents.enabledAgents = [
    "claude"
    "omp"
  ];
  mdarocha.neovim.enable = true;

  # NixOS already provides GPU drivers, FHS integration and man pages
  targets.genericLinux.enable = false;
  programs.man.generateCaches = false;
}
