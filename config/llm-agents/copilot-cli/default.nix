{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  copilotCli = cfg.copilot-cli;

  wrapped = cfg.wrapper {
    name = "copilot";
    home = ".copilot";
    program = "${pkgs.llm-agents.copilot-cli}/bin/copilot";
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
          (cfg.networkLogInstructions ".copilot")
        ];
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".copilot/skills/${name}" { source = dir; }
      ) cfg.skills)
    ];
  };
}
