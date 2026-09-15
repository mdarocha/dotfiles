{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  copilotCli = cfg.copilot-cli;
in
{
  options.mdarocha.llm-agents.copilot-cli.enable = lib.mkEnableOption "GitHub Copilot CLI";

  config = lib.mkIf copilotCli.enable {
    home.packages = [ pkgs.llm-agents.copilot-cli ];

    home.file = lib.mkMerge [
      {
        ".copilot/AGENTS.md".text = cfg.instructions;
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".copilot/skills/${name}" { source = dir; }
      ) cfg.skills)
    ];
  };
}
