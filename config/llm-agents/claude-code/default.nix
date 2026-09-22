{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents.claude-code;
  common = config.mdarocha.llm-agents;
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;

  binName = "claude";

  wrapped = pkgs.writeShellScriptBin binName ''
    export PATH="${lib.makeBinPath common.environment.path}:$PATH"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value: "export ${name}=${lib.escapeShellArg value}"
      ) common.environment.env
    )}
    exec ${cfg.package}/bin/${binName} "$@"
  '';
in
{
  options.mdarocha.llm-agents.claude-code = {
    enable = mkEnableOption "Claude Code";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.llm-agents.claude-code;
      description = "Claude Code package to install, or null where the environment already ships its own binary.";
    };
  };

  config = mkIf cfg.enable {
    # cfg.package == null means the environment already ships its own
    # claude binary, so there is nothing here to wrap with our PATH/env.
    home.packages = lib.optional (cfg.package != null) wrapped;

    home.file = {
      ".claude/CLAUDE.md".text = lib.concatStringsSep "\n" [
        common.instructions
        common.environment.instructions
      ];
    }
    // lib.mapAttrs' (
      name: dir: lib.nameValuePair ".claude/skills/${name}" { source = dir; }
    ) common.skills;
  };
}
