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
    home.packages = lib.optional (cfg.package != null) cfg.package;

    home.file = {
      ".claude/CLAUDE.md".text = common.instructions;
    }
    // lib.mapAttrs' (
      name: dir: lib.nameValuePair ".claude/skills/${name}" { source = dir; }
    ) common.skills;
  };
}
