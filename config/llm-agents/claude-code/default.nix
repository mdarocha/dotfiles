{
  config,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
in
{
  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge [
      {
        # Global instructions and hooks, applied to every repo/session on
        # this machine — not tied to any single project's checkout.
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
      # Symlink each skill directory to ~/.claude/skills/<name>/
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".claude/skills/${name}" { source = dir; }
      ) cfg.common.skills)
    ];
  };
}
