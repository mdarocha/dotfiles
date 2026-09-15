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
  config = lib.mkIf cfg.enable {
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
