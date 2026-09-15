{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents.cursor-agent;
in
{
  options.mdarocha.llm-agents.cursor-agent.enable = lib.mkEnableOption "Cursor Agent CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.cursor-agent ];
  };
}
