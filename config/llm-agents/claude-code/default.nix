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
  options.mdarocha.llm-agents.claude-code-web.enable =
    mkEnableOption "Claude Code (web) agent config";

  config = mkIf (cfg.enable || cfg.claude-code-web.enable) {
    home.file = lib.mkMerge [
      {
        # TODO: select the mode chunk at runtime via a SessionStart hook, like the
        # oh-my-pi extension does. Claude Code has no native TypeScript hook that can
        # replace the system prompt, so it gets the self-detecting full text for now.
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
