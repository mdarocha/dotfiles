{ config, lib, ... }:

let
  cfg = config.mdarocha.llm-agents;
  inherit (lib) mkOption types;

  # Renders one domain group value as a human-readable string for the agent.
  # A plain list becomes "`d1`, `d2`" (any method implied).
  # An attrset renders each domain with its method constraint if not "*".
  renderDomainGroup =
    value:
    if builtins.isList value then
      lib.concatMapStringsSep ", " (d: "`${d}`") value
    else
      lib.concatStringsSep ", " (
        lib.mapAttrsToList (
          domain: methods:
          if methods == "*" then
            "`${domain}`"
          else
            "`${domain}` (${lib.concatStringsSep ", " methods} only)"
        ) value
      );
in
{
  options.mdarocha.llm-agents.common = {
    agentInstructions = mkOption {
      type = types.str;
      description = "Common agent instructions injected as AGENTS.md for all configured agents.";
      default = ''
        ## Sandbox network restrictions

        You are running inside a sandboxed environment. Outbound network access is restricted
        by a filtering proxy. WebFetch and other HTTP requests will fail with connection
        errors for any disallowed domain or method.

        Domains use suffix matching: an entry like `github.com` also covers `api.github.com`,
        `raw.github.com`, and any other subdomain.

        ${if cfg.sandbox.allowGetAnywhere then "GET and HEAD requests are allowed to **any** domain — use these freely for web search and browsing." else ""}
        All other methods are restricted to the domains below:

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: value: "- ${name}: ${renderDomainGroup value}"
          ) cfg.sandbox.allowedDomainGroups
        )}

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

        ## Comments

        - Comment *why*, not *what*. Delete any comment that only restates what the code
          plainly does — assume the reader can read code.
        - Never describe the edit or its history; the diff and git log record that. Banned:
          `// changed from ...`, `// was previously ...`, `// removed ...`, `// renamed ...`,
          `// updated to ...`, `// new`, `// now handles ...`, `// (old logic below)`.
        - When editing, write code as if it had always been this way. Don't annotate what
          changed vs. the old version. Match the surrounding comment density.
        - Never leave commented-out code. Delete it. No block-by-block walkthroughs or
          decorative banners.
        - Keep inline comments only for: non-obvious rationale, edge cases, business rules
          not visible in the code, and workarounds (link the issue).
        - Doc comments are the API contract for the public surface, not every private
          helper — follow the file's existing convention. Document behavior, invariants,
          units, and error/panic conditions; never restate the name and type
          (`@param id — the id`). No empty or placeholder doc stubs. Use the language's
          native format (rustdoc `///`, TSDoc `/** */`, XML `/// <summary>`).
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

    rules = mkOption {
      type = types.attrsOf types.path;
      description = "Map of rule name to source path. Each rule is written to all configured agents.";
      default = {
        no-nix-store-source-search = ./rules/no-nix-store-source-search.md;
      };
    };
  };
}
