{ config, pkgs, lib, ... }:

let
  cfg = config.mdarocha.llm-agents;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      (cfg.sandbox.wrapPackage "omp" pkgs.llm-agents.omp)
    ];

    home.file = {
      # Inject sandbox rules as the global agent context file.
      # oh-my-pi discovers AGENTS.md files via universal config discovery.
      ".omp/agent/AGENTS.md".text = ''
        ## Sandbox network restrictions

        You are running inside a sandboxed environment. Outbound network access is restricted
        to an allowlist of domains. WebFetch and other HTTP requests will fail with connection
        errors for any domain not listed below.

        Allowed domains:
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: domains: "- ${name}: ${lib.concatMapStringsSep ", " (d: "`${d}`") domains}") cfg.sandbox.allowedDomainGroups)}

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

      ".omp/agent/skills/commit/SKILL.md".source = ./skills/commit/SKILL.md;
      ".omp/agent/skills/gh-cli/SKILL.md".source = ./skills/gh-cli/SKILL.md;
      ".omp/agent/skills/run-with-nix/SKILL.md".source = ./skills/run-with-nix/SKILL.md;
    };
  };
}
