{
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;
in
{
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
  };
}
