{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;

  opencode = pkgs.llm-agents.opencode; # TODO broken (import ./web-ui.nix { inherit pkgs lib; }).opencode-patched;
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
        ## Sandbox network restrictions

        You are running inside a sandboxed environment. Outbound network access is restricted
        to an allowlist of domains. WebFetch and other HTTP requests will fail with connection
        errors for any domain not listed below.

        Allowed domains:
        - GitHub: `github.com`, `*.github.com`, `*.githubusercontent.com`
        - GitHub Copilot: `*.githubcopilot.com`, `default.exp-tas.com`
        - npm: `registry.npmjs.org`, `npmjs.org`, `registry.yarnpkg.com`
        - Python: `pypi.org`, `files.pythonhosted.org`
        - Nix: `cache.nixos.org`, `cache.numtide.com`, `*.cachix.org`, `channels.nixos.org`
        - Azure DevOps: `dev.azure.com`, `*.visualstudio.com`, `login.microsoftonline.com`
        - MCP tools: `mcp.grep.app`, `mcp.exa.ai`
        - Other: `models.dev`
        - NuGet: `api.nuget.org`

        Notably **not** allowed: `opencode.ai`, `reddit.com`, `stackoverflow.com`,
        `medium.com`, generic web search result domains. Do not attempt to fetch pages
        from these sites -- the requests will fail silently or time out.

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
        plugin = [
          "file://${./plugins/copilot-fix-models.js}"
        ];
        model = "github-copilot/claude-sonnet-4.6";

        # Used for title generation, compaction, and summaries. gpt-5-mini is
        # lightweight and free on GitHub Copilot (1× premium request).
        small_model = "github-copilot/gpt-5-mini";

        agent = {
          general = {
            model = "github-copilot/claude-sonnet-4.6";
          };
          summary = {
            model = "github-copilot/claude-haiku-4.5";
          };
          compaction = {
            model = "github-copilot/claude-sonnet-4.6";
          };
          explore = {
            model = "github-copilot/claude-haiku-4.5";
          };
          plan = {
            model = "github-copilot/claude-opus-4.6";
          };
        };

        # Prevent the opencode provider from loading entirely. Without this,
        # it auto-activates with apiKey: "public" and silently routes title
        # generation, compaction, and summary tasks through opencode.ai/zen.
        disabled_providers = [ "opencode" ];
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
            "/nix/store/*" = "allow";
            "/tmp/*" = "allow";
            "*" = "ask";
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
