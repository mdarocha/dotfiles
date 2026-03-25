{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
in
{
  imports = [
    ./sandbox
    ./opencode
    ./copilot-cli
    ./oh-my-pi
  ];

  options.mdarocha.llm-agents = {
    enable = lib.mkEnableOption "llm-agents";
  };

  config = lib.mkIf cfg.enable {
    # runtimes commonly used by agents for tool execution
    home.packages = [
      pkgs.python3
      pkgs.nodejs
      pkgs.nodePackages.npm
      pkgs.bun
    ];
  };
}
