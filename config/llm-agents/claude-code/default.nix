{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  claudeCode = cfg.claude-code;
  inherit (lib) mkOption mkEnableOption mkIf types;
in
{
  options.mdarocha.llm-agents.claude-code = {
    enable = mkEnableOption "Claude Code";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.llm-agents.claude-code;
      description = "Claude Code package to install, or null where the environment already ships its own binary.";
    };

    fixNix = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Install a SessionStart hook that puts Nix on PATH. Needed in environments
        where the Bash tool's shell never sources the Nix profile scripts.
      '';
    };
  };

  config = mkIf claudeCode.enable {
    home.packages = lib.optional (claudeCode.package != null) claudeCode.package;

    home.file = lib.mkMerge [
      { ".claude/CLAUDE.md".text = cfg.instructions; }
      (mkIf claudeCode.fixNix {
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
      })
      (lib.mapAttrs' (name: dir: lib.nameValuePair ".claude/skills/${name}" { source = dir; }) cfg.skills)
    ];
  };
}
