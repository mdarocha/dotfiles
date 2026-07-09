{ config, lib, ... }:

let
  cfg = config.mdarocha.llm-agents;
  inherit (lib) mkOption types;
in
{
  options.mdarocha.llm-agents.common = {
    agentInstructions = mkOption {
      type = types.str;
      description = "Common agent instructions injected as AGENTS.md for all configured agents.";
      default = ''
        ## Sandbox network restrictions

        You are running inside a sandboxed environment. Outbound network access is restricted
        to an allowlist of domains. WebFetch and other HTTP requests will fail with connection
        errors for any domain not listed below.

        Domains use suffix matching: an entry like `github.com` also covers `api.github.com`,
        `raw.github.com`, and any other subdomain.

        Allowed domains:
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: domains: "- ${name}: ${lib.concatMapStringsSep ", " (d: "`${d}`") domains}"
          ) cfg.sandbox.allowedDomainGroups
        )}

        Notably **not** allowed: `opencode.ai`, `reddit.com`, `stackoverflow.com`,
        `medium.com`, generic web search result domains. Do not attempt to fetch pages
        from these sites -- the requests will fail silently or time out.

        ## Localhost / loopback isolation

        The sandbox network namespace is isolated from the host. `localhost` (`127.0.0.1`)
        inside the sandbox is the **sandbox's own loopback** -- it does **not** reach services
        running on the host machine. The host is only reachable via the pasta gateway
        (`10.0.2.2`), which is itself proxy-filtered and not useful for dev servers.

        Consequence: if a task requires a locally-running service (dev server, test server,
        database, etc.), **the agent must start it** via `bash` inside the current session.
        Asking the user to start it on their machine and then connecting to it will not work.

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

        ## Documentation search

        Use the **context7 MCP** to fetch current, version-accurate documentation for any library, framework,
        SDK, API, CLI tool, or cloud service — including well-known ones like React, Next.js, Prisma, Django,
        Spring Boot, or Tailwind. Prefer this over web search for library docs, since your training data may
        not reflect recent changes. Use it for: API syntax, configuration, version migration, library-specific
        debugging, setup instructions, and CLI tool usage.
      '';
    };

    skills = mkOption {
      type = types.attrsOf types.path;
      description = "Map of skill name to SKILL.md source path. Each skill is written to all configured agents.";
      default = {
        commit = ./skills/commit/SKILL.md;
        github = ./skills/github/SKILL.md;
        run-with-nix = ./skills/run-with-nix/SKILL.md;
        verify = ./skills/verify/SKILL.md;
        simplify = ./skills/simplify/SKILL.md;
      };
    };
  };
}
