{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  packages = cfg.sandbox.wrapPackages "copilot" pkgs.llm-agents.copilot-cli;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      packages.sandbox
      packages.no-sandbox
    ];

    home.file = lib.mkMerge [
      {
        # TODO: select the mode chunk at runtime via a sessionStart hook, like the
        # oh-my-pi extension does. Copilot CLI hooks can only inject additionalContext,
        # never replace the loaded AGENTS.md, so it gets the self-detecting full text.
        ".copilot/AGENTS.md".text = cfg.common.agentInstructions;
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".copilot/skills/${name}" { source = dir; }
      ) cfg.common.skills)
    ];
  };
}
