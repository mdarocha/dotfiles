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

  wrapped = pkgs.writeShellScriptBin binName ''
    export PATH="${lib.makeBinPath cfg.environment.path}:$PATH"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") cfg.environment.env
    )}
    exec ${pkgs.llm-agents.copilot-cli}/bin/${binName} "$@"
  '';
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
        ];
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".copilot/skills/${name}" { source = dir; }
      ) cfg.skills)
    ];
  };
}
