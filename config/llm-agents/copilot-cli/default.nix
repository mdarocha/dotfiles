{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  copilotCli = cfg.copilot-cli;

  binName = "copilot";
  agentHome = ".copilot";

  wrapped = cfg.wrapper {
    name = binName;
    home = agentHome;
    program = "${pkgs.llm-agents.copilot-cli}/bin/${binName}";
  };
in
{
  options.mdarocha.llm-agents.copilot-cli.enable = lib.mkEnableOption "GitHub Copilot CLI";

  config = lib.mkIf copilotCli.enable {
    home.packages = [ wrapped ];

    home.file = lib.mkMerge [
      {
        ".copilot/AGENTS.md".text = lib.concatStringsSep "\n" [
          cfg.instructions
          cfg.environment.instructions
          (cfg.networkLogInstructions agentHome)
        ];
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".copilot/skills/${name}" { source = dir; }
      ) cfg.skills)
    ];
  };
}
