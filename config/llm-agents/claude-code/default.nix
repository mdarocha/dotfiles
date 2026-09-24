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

  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  toolRulesHook = {
    type = "command";
    command = lib.escapeShellArgs [
      python.interpreter
      "${./hooks/tool_rules.py}"
      "--repeat-mode"
      common.ruleRepeat.mode
      "--repeat-gap"
      (toString common.ruleRepeat.gap)
    ];
  };

  # Passed with --settings so ~/.claude/settings.json stays writable by Claude
  # Code; hooks from both sources merge.
  settings = (pkgs.formats.json { }).generate "claude-settings.json" {
    hooks =
      lib.genAttrs
        [
          "PreToolUse"
          "PostToolBatch"
          "Stop"
          "SubagentStop"
          "SessionEnd"
        ]
        (_: [
          { hooks = [ toolRulesHook ]; }
        ]);
  };

  wrapped = pkgs.writeShellScriptBin binName ''
    export PATH="${lib.makeBinPath common.environment.path}:$PATH"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value: "export ${name}=${lib.escapeShellArg value}"
      ) common.environment.env
    )}
    exec ${cfg.package}/bin/${binName} --settings ${settings} "$@"
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

    home.file = lib.mkMerge [
      {
        ".claude/CLAUDE.md".text = lib.concatStringsSep "\n" [
          common.instructions
          common.environment.instructions
          common.environment.hostInstructions
        ];
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".claude/skills/${name}" { source = dir; }
      ) common.skills)
      # Not ~/.claude/rules, which Claude Code loads into every session as memory.
      (lib.mapAttrs' (
        name: src: lib.nameValuePair ".claude/tool-rules/${name}.md" { source = src; }
      ) common.rules)
    ];
  };
}
