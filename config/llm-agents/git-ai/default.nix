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
  options.mdarocha.llm-agents.git-ai = {
    enable = lib.mkEnableOption "git-ai AI-authorship tracking";
  };

  config = lib.mkIf (cfg.enable && cfg.git-ai.enable) {
    home.packages = [ pkgs.git-ai ];

    home.file = {
      ".git-ai/config.json".text = builtins.toJSON {
        telemetry_oss_disabled = true;
        disable_version_checks = true;
        disable_auto_updates = true;
        feature_flags.daemon_log_upload = false;
      };

      ".omp/agent/extensions/git-ai.ts".source = "${pkgs.git-ai}/share/git-ai/oh-my-pi.ts";

      ".omp/agent/git-ai.override.json".text = builtins.toJSON {
        version = 1;
        tools.ast_edit = {
          kind = "mutating";
          canonical = "replace";
          filepath_fields = [ "paths" ];
        };
      };
    };
  };
}
