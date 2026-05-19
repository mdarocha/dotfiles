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
    home.packages = [
      (cfg.sandbox.wrapPackage "copilot" pkgs.llm-agents.copilot-cli)
    ];

    home.file = lib.mkMerge [
      {
        # Inject common instructions as the global agent context file.
        ".copilot/AGENTS.md".text = cfg.common.agentInstructions;
      }
      # Write each skill to ~/.copilot/skills/<name>/SKILL.md
      (lib.mapAttrs' (
        name: src: lib.nameValuePair ".copilot/skills/${name}/SKILL.md" { source = src; }
      ) cfg.common.skills)
    ];
  };
}
