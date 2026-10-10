{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents.cursor-agent;
  common = config.mdarocha.llm-agents;

  binName = "cursor-agent";
  agentHome = ".cursor";

  # Injecting --add-dir before these breaks commander's dispatch: the flag
  # is only registered on the default agent invocation, not on these
  # subcommands, so route them straight through instead.
  passthroughSubcommands = [
    "persist"
    "install-shell-integration"
    "uninstall-shell-integration"
    "login"
    "logout"
    "mcp"
    "plugin"
    "worker"
    "status"
    "whoami"
    "models"
    "bedrock"
    "about"
    "update"
    "create-chat"
    "generate-rule"
    "rule"
    "agent"
    "ls"
    "resume"
    "help"
  ];

  # cursor-agent has no user-level rules file: AGENTS.md/.cursor/rules are
  # discovered per workspace root only. It merges rules from every
  # `--add-dir` root alongside the primary workspace, so pointing it at a
  # fixed store path applies these instructions regardless of the invoking
  # project.
  globalRulesDir = pkgs.writeTextDir "AGENTS.md" (
    lib.concatStringsSep "\n" [
      common.instructions
      common.environment.instructions
      (common.networkLogInstructions agentHome)
    ]
  );

  package = common.wrapper {
    name = binName;
    home = agentHome;
    program = "${pkgs.llm-agents.cursor-agent}/bin/${binName}";
    preExec = ''
      case "''${1:-}" in
        ${lib.concatStringsSep "|" passthroughSubcommands}) ;;
        *) set -- --add-dir ${globalRulesDir} "$@" ;;
      esac
    '';
  };
in
{
  options.mdarocha.llm-agents.cursor-agent.enable = lib.mkEnableOption "Cursor Agent CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    home.file = lib.mapAttrs' (
      name: dir: lib.nameValuePair ".cursor/skills/${name}" { source = dir; }
    ) common.skills;
  };
}
