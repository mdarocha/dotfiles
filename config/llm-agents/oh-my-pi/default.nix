{ config, pkgs, lib, ... }:

let
  cfg = config.mdarocha.llm-agents;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      (cfg.sandbox.wrapPackage "omp" pkgs.llm-agents.omp)
    ];

    home.file = lib.mkMerge [
      {
        # Inject common instructions as the global agent context file.
        # oh-my-pi discovers AGENTS.md files via universal config discovery.
        ".omp/agent/AGENTS.md".text = cfg.common.agentInstructions;
      }
      # Write each skill to ~/.omp/agent/skills/<name>/SKILL.md
      (lib.mapAttrs' (name: src:
        lib.nameValuePair ".omp/agent/skills/${name}/SKILL.md" { source = src; }
      ) cfg.common.skills)
    ];
  };
}
