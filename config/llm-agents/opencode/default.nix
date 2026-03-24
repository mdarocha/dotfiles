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
  imports = [
    ./permissions/git.nix
    ./permissions/gh.nix
    ./skills
  ];

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = cfg.sandbox.wrapPackage "opencode" pkgs.llm-agents.opencode;
      settings = {
        share = "disabled";
        mcp = {
          grep = {
            type = "remote";
            url = "https://mcp.grep.app";
          };
        };
        permission = {
          "*" = "allow";

          external_directory = {
            "*" = "ask";
            "/tmp" = "allow";
            "/tmp/*" = "allow";
          };

          bash = {
            "*" = "allow";

            # deny privilege escalation
            "sudo *" = "deny";
            "su *" = "deny";
          };
        };
      };
    };
  };
}
