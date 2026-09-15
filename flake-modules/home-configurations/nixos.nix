{
  home = {
    username = "mdarocha";
    homeDirectory = "/home/mdarocha";
  };

  mdarocha = {
    llm-agents = {
      claude-code.enable = true;
      oh-my-pi.enable = true;
    };
    zed = {
      enable = true;
      configDir = "/home/mdarocha/.config/zed";
    };
  };

  # NixOS already provides GPU drivers, FHS integration and man pages
  targets.genericLinux.enable = false;
  programs.man.generateCaches = false;
}
