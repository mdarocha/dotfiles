{
  config,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.mdarocha.llm-agents.claude-code-web.enable = mkEnableOption "Claude Code (web) agent config";

  config = mkIf cfg.claude-code-web.enable {
    home.file = lib.mkMerge [
      {
        ".claude/CLAUDE.md".text = cfg.common.agentInstructions;

        ".claude/hooks/fix-nix-path.sh" = {
          source = ./fix-nix-path.sh;
          executable = true;
        };

        ".claude/settings.json".text = builtins.toJSON {
          hooks.SessionStart = [
            {
              hooks = [
                {
                  type = "command";
                  command = "$HOME/.claude/hooks/fix-nix-path.sh";
                }
              ];
            }
          ];
        };
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".claude/skills/${name}" { source = dir; }
      ) cfg.common.skills)
    ];
  };
}
