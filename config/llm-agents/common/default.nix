{
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;

  ruleFiles = lib.filterAttrs (file: kind: kind == "regular" && lib.hasSuffix ".md" file) (
    builtins.readDir ./rules
  );
in
{
  imports = [ ./environment.nix ];

  options.mdarocha.llm-agents = {
    instructions = mkOption {
      type = types.str;
      description = "Instructions shared by every configured agent.";
      default = builtins.readFile ./instructions.md;
    };

    skills = mkOption {
      type = types.attrsOf types.path;
      description = "Map of skill name to source directory. Each skill is symlinked into all configured agents.";
      default = {
        commit = ./skills/commit;
        github = ./skills/github;
        run-with-nix = ./skills/run-with-nix;
        verify = ./skills/verify;
        simplify = ./skills/simplify;
        pdf = "${inputs.anthropics-skills}/skills/pdf";
        docx = "${inputs.anthropics-skills}/skills/docx";
        pptx = "${inputs.anthropics-skills}/skills/pptx";
        xlsx = "${inputs.anthropics-skills}/skills/xlsx";
        frontend-design = "${inputs.anthropics-skills}/skills/frontend-design";
        humanizer = inputs.humanizer;
      };
    };

    rules = mkOption {
      type = types.attrsOf types.path;
      description = "Map of rule name to rule file in oh-my-pi's rule format (TTSR frontmatter). Agents without native support enforce them through hooks.";
      default = lib.mapAttrs' (
        file: _: lib.nameValuePair (lib.removeSuffix ".md" file) (./rules + "/${file}")
      ) ruleFiles;
    };

    ruleRepeat = {
      mode = mkOption {
        type = types.enum [
          "once"
          "after-gap"
        ];
        default = "after-gap";
        description = "Whether a triggered rule stays silent for the rest of the session or may trigger again after `gap` turns.";
      };

      gap = mkOption {
        type = types.ints.positive;
        default = 5;
        description = "Completed turns before a triggered rule may trigger again in `after-gap` mode.";
      };
    };
  };
}
