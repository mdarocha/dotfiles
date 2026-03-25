{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;

  opencode =
    pkgs.runCommand "opencode"
      {
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
      }
      ''
        mkdir -p $out/bin
        makeBinaryWrapper ${lib.getExe' pkgs.llm-agents.opencode "opencode"} $out/bin/opencode \
          --set OPENCODE_ENABLE_EXA true
      '';
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
      package = cfg.sandbox.wrapPackage "opencode" opencode;
      rules = ''
        ## Code search tool selection

        When searching for code outside the current project, choose the right tool:

        1. **grep MCP** (preferred for public code): Use the `grep` MCP server for searching public code on GitHub.
           It performs fast literal and regex pattern matching across millions of repositories.
           Best for: finding usage examples, API patterns, library idioms, and real-world code snippets.

        2. **gh CLI** (for private/org code): Use `gh search code` when results from private or organization
           repositories are needed, since the grep MCP only indexes public code.
           Also useful when you need to scope searches to a specific owner or repository.

        3. **codesearch** (fallback): Use the `codesearch` tool when the grep MCP doesn't return good results.
           It uses semantic/neural search (via Exa AI) rather than pattern matching, so it can find
           conceptually relevant code, documentation, and examples even when you don't know the exact syntax.
      '';
      settings = {
        model = "github-copilot/claude-opus-4.6";
        share = "disabled";
        mcp = {
          grep = {
            type = "remote";
            url = "https://mcp.grep.app";
          };
        };
        permission = {
          "*" = "allow";

          # The sandbox already enforces filesystem boundaries, so there is
          # no need for opencode to prompt on external directory access.
          external_directory = {
            "*" = "allow";
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
