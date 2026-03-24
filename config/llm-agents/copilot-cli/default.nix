{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      (cfg.sandbox.wrapPackage "copilot" pkgs.llm-agents.copilot-cli)
    ];
  };
}
