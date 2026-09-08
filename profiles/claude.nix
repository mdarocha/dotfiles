{
  imports = [
    ./common/generic-linux.nix
    ./common/container.nix
  ];

  mdarocha.llm-agents.claude-code-web.enable = true;

  home = {
    username = "root";
    homeDirectory = "/root";
  };
}
