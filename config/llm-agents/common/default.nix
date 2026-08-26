{
  config,
  lib,
  inputs,
  ...
}:

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
          if methods == "*" then "`${domain}`" else "`${domain}` (${lib.concatStringsSep ", " methods} only)"
        ) value
      );
in
{
  options.mdarocha.llm-agents.common = {
    base = mkOption {
      type = types.str;
      description = "Instructions that hold in both execution variants.";
      default = ''
        ## Provisioned CLI tools

        These packages are provisioned by Nix and should be always available, alongside `nix` itself:

        ${lib.concatMapStringsSep ", " (n: "`${n}`") cfg.sandbox.packageDescriptions}

        Do not assume a tool outside this list exists — check first. If you need one
        that is not provisioned, use `nix run nixpkgs#<package>` or
        `nix shell nixpkgs#<package>` to get it temporarily instead of installing it (see the `run-with-nix` skill).

        ## Python execution environment

        Python dependencies are provisioned through a Nix-managed environment that the
        `eval` tool's Python kernel already has access to. `VIRTUAL_ENV` points at that
        same environment in both variants, so you MUST NOT install packages at runtime —
        `pip install`, `uv pip install`, `pip install --user`, `python -m pip`, or any
        other package manager invocation will fail or produce results silently discarded
        when the session ends.

        Pre-installed Python packages: ${
          lib.concatMapStringsSep ", " (n: "`${n}`") cfg.sandbox.pythonPackageNames
        }

        If a task requires a package not listed above:
        1. Tell the user which package is missing and that it must be added to the
           sandbox config (`pythonEvalEnv` in [`config/llm-agents/sandbox/default.nix`](https://github.com/mdarocha/dotfiles/blob/main/config/llm-agents/sandbox/default.nix)).
        2. Do NOT work around the absence by downloading wheels, vendoring source, or
           running `pip` with `--target`.

        **WRONG:**
        ```python
        import subprocess
        subprocess.run(["pip", "install", "requests"])  # FAILS: the Nix env cannot be extended at runtime
        ```

        **RIGHT:**
        ```python
        import pandas as pd  # already available, just import it
        df = pd.read_csv("data.csv")
        ```
        
        ## Git LFS

        Do **not** run `git lfs install`: LFS filters are already configured
        globally (`filter.lfs.*` in `~/.config/git/config`, provisioned by
        home-manager's `programs.git.lfs.enable`), `add`/`commit`/`push`/`checkout` already
        smudge/clean LFS-tracked files correctly without any per-repo
        `.git/config` entries. `git-lfs` itself is on `$PATH`.

        ## Browser GPU acceleration

        Some tasks (ie. WebGL rendering, in-browser ML) REQUIRE GPU acceleration in the browser, since they are too
        slow without it.

        Confirm the actual GPU backend via `chrome://gpu`'s "Graphics Feature Status"
        and `GPU0` fields, not `WEBGL_debug_renderer_info` / `navigator.userAgent` —
        the browser tool spoofs those for fingerprinting resistance regardless of the
        real backend.

        GPU availability depends on whether: (1) the required /dev/dri is currently available
        (it can be unavailable if the current machine has no GPU, or because it's sandboxed out),
        (2) the browser is not running in "headless" mode.

        If Chromium is running headless but the task genuinely needs GPU-backed
        rendering (e.g. WebGL correctness, GPU compute), headless mode cannot provide
        it — ask the user to switch the browser tool to visible/non-headless mode and
        relaunch it.

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

        No comment is the default, because well-named code is self-documenting. Before
        writing one, name which of these it is — if none fit, do not write it:

        1. a *why* the code cannot show: a constraint, spec requirement, or business rule,
        2. an edge case a reader would not predict,
        3. a workaround, with the issue linked,
        4. a doc comment on a public surface, stating behavior, invariants, units, and
           error/panic conditions in the language's native format.

        Never write these, in any language: restatements of the line below, structural
        labels (`# imports`, `# helper`), phase headers (`// Step 1: validate`),
        decorative separators, summaries of the function they sit above, edit history
        (`// changed from`, `// now handles`, `// new`), commented-out code, chatter
        aimed at the reviewer (`// as requested`), doc text that restates a name and
        type (`@param id — the id`), or anything tied to the current session, host, or
        sandbox rather than the code.

        Two constraints outrank the list above:

        - **Density.** Match the file's existing comment level and never raise it. Bulk
          narration is rejected even when each line is individually defensible.
        - **Durability.** Write edits as if the code had always been that way, and keep
          every comment true after the next refactor.

        This is enforced, not advisory: comment shapes from the banned list abort the
        edit that writes them, and the diff is audited for narration and density before
        a session settles. Deleting a comment is always the cheaper path.

        ## Code style preferences

        - Avoid magic numbers and strings: extract recurring or meaningful values
          into named constants or enums. Leave self-explanatory, one-off values
          inline — don't create a constant just to name something obvious. If a
          value comes from an external spec (e.g. HTTP 200), name it regardless.
        - Reduce nesting: prefer early return/continue over deeply nested
          conditionals (avoid the arrow anti-pattern).
        - Prefer enums over boolean parameters when a function takes more than one
          flag — call sites read better as a named variant than a wall of
          `true`/`false`.
        - Give logical blocks of code room to breathe with blank lines; don't cram
          unrelated statements together.
        - Keep function names short and descriptive. A name that needs much more
          than ~30 characters is usually a sign to find a better abstraction or
          split the function, not to keep shortening the name.
        - Treat visibility changes as a design decision: keep fields and functions
          private unless external access is actually required. Ask before widening
          an access modifier from private to internal/public.
        - Encapsulate low-level mechanics (raw I/O, protocol parsing, direct
          socket/DB access) behind a dedicated layer, and expose higher layers a
          clean API in terms of domain concepts rather than implementation
          details. Don't let a caller reach through an abstraction layer to talk
          to what's underneath it directly.
        - Always use braces on conditionals and loops, even for single-statement
          bodies.
        - When fixing a reported bug, first write a failing test that reproduces
          it, confirm it fails, then write the fix and confirm the test passes.
        - Don't touch code unrelated to the change you're making. Minimize the
          number of changed lines — e.g. don't add comments or reformat a block
          you didn't otherwise need to modify.

        ## Communication style

        - In prose meant for a human (chat replies, PR descriptions), use as few
          words as possible — pick each word deliberately rather than padding.
        - Skip superlatives and validation ("you're absolutely right", "great
          question"). State the assessment plainly, including when something is
          wrong.

        ## Long sessions and context dilution

        Instructions placed in the middle of a long context get less attention
        than those at the start or end (the "lost in the middle" effect), and
        code quality can visibly drift as a session grows. If you notice output
        drifting from these instructions, re-read this file rather than trying to
        course-correct piecemeal. Prefer starting a fresh session per
        feature/task over one long session that accumulates unrelated context.

      '';
    };

    sandbox = mkOption {
      type = types.str;
      description = "Instructions that hold only inside the sandbox.";
      default = ''
        You are running inside a sandbox.

        ## Toolset limits (sandbox only)

        Inside the sandbox the provisioned list is **all** there is: no other binaries
        are on PATH and none of the host's own tools leak in. Check that list before
        reaching for a command, and pull anything missing using Nix.

        ## direnv and devenv (sandbox only)

        `direnv` and `devenv` are **not** in the sandbox PATH. In most cases you do
        **not need them** — the sandbox already provides the common development tools
        listed above (git, node, cargo, python, etc.). Only reach for direnv/devenv
        when the project requires project-specific tools or environment variables that
        are not already on PATH.

        If you do need them:
        - **direnv:** `nix run nixpkgs#direnv -- allow . && eval "$(nix run nixpkgs#direnv -- export bash)"`
        - **devenv:** `nix run github:cachix/devenv -- shell` or `nix develop`
        - **nix develop:** If the project has a `flake.nix` with `devShells`, use
          `nix develop --command <cmd>` directly — `nix` is always available.

        ## Network restrictions (sandbox only)

        Outbound network access is restricted by a filtering proxy. HTTP requests will
        fail with connection errors for any disallowed domain or method.

        Also note that the network proxy will allow ONLY http requests - this means any non-HTTP
        network calls like SSH or custom protocols will always fail. If you need them, inform the user
        that they need to disable the sandbox by running the `-nosandbox` variant of your binary.

        All blocked requests will show up in `/tmp/sandbox-proxy.log`. You don't have access to this file while inside the sandbox.
        If you suspect your issue is caused by sandbox blocking a network request, inform the user that they should check there.

        Domains use suffix matching: `github.com` also covers `api.github.com`,
        `raw.github.com`, and any other subdomain.

        ${
          if cfg.sandbox.allowGetAnywhere then
            "GET and HEAD requests are allowed to **any** domain — use these freely for web search and browsing."
          else
            ""
        }
        All other methods are restricted to the domains below:

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: value: "- ${name}: ${renderDomainGroup value}"
          ) cfg.sandbox.allowedDomainGroups
        )}

        ## Localhost / loopback isolation (sandbox only)

        The sandbox network namespace is isolated from the host. `localhost` (`127.0.0.1`)
        inside the sandbox is the **sandbox's own loopback** — it does **not** reach services
        running on the host machine.

        Consequence: if a task requires a locally-running service (dev server, database,
        etc.), **the agent must start it** via `bash` inside the current session.
        Asking the user to start it on their machine and then connecting to it will not work.

        ## Windows filesystem paths (sandbox only)

        Under WSL the Windows drives (`/mnt/c`, `/mnt/d`, …) are **not** reachable: the
        sandbox binds only an explicit set of directories into its filesystem namespace.
        If a task needs Windows-side files, run the `-nosandbox` variant instead, or ask
        the user to copy them into the Linux filesystem first.

        ## `.git/config` (sandbox only)

        `.git/config` in a project checkout is **read-only** inside the sandbox — any
        write to it, e.g. `git config --local ...`, fails with "Device or resource
        busy" / "Read-only file system". This is not repo-specific; it applies to
        every checkout.
      '';
    };

    no-sandbox = mkOption {
      type = types.str;
      description = "Instructions that hold only outside the sandbox (the `-nosandbox` variant).";
      default = ''
        You are running without any sandboxing applied - full system access is available.

        ## Host mode (no sandbox)

        These rules apply when running outside the sandbox, through the `-nosandbox`
        variant:

        - **Network:** unrestricted. There is no filtering proxy and no domain allowlist,
          so every method reaches every host.
        - **Localhost:** `localhost` is the host's own loopback, so a service the user
          started outside this session is reachable, and you do not have to start one
          yourself to talk to it.
        - **Filesystem:** the real host filesystem, with no bind-mount allowlist.
          `.git/config` is writable, but `git lfs install` is still unnecessary — LFS
          filters are configured globally in `~/.config/git/config`.
        - **PATH:** the provisioned tools are prepended, but that list is not exhaustive
          here — the host may provide plenty more besides.
        - **direnv / devenv:** both work normally if they are installed on the host.

        ## WSL environment

        When running under WSL (Windows Subsystem for Linux), Windows filesystem paths
        are available under `/mnt/c`, `/mnt/d`, etc. You can read and write files on the
        Windows side directly — for example, `ls /mnt/c/Users` lists Windows user
        directories. Check for WSL by inspecting the kernel version:

        ```bash
        grep -qi microsoft /proc/version 2>/dev/null && echo "WSL" || echo "native"
        ```

      '';
    };

    # TODO: this is required only for the full `agentInstructions` field, and can be removed
    # once we remove `agentInstructions`.
    sandbox-detection = mkOption {
      type = types.str;
      description = "Runtime mode-detection procedure. Only meaningful where both mode sections are present.";
      default = ''
        ## Sandbox detection

        You may be running inside a sandboxed environment or directly on the host, and
        this document carries the rules for both. **You MUST determine which mode you
        are in before relying on any mode-specific rule below.** Check the
        `MDAROCHA_AGENT_SANDBOX` environment variable once at session start:

        ```bash
        echo "$MDAROCHA_AGENT_SANDBOX"
        ```

        - `1` → you are **inside** the sandbox. Apply every **(sandbox only)** section
          and skip the host-mode section.
        - unset/empty → you are **outside** the sandbox (the `-nosandbox` variant). Skip
          every **(sandbox only)** section and apply the host-mode section instead.

      '';
    };

    # TODO: all agents should be moved to dynamic hooks for building sandbox/nosandbox instructions,
    # and this field should be removed.
    agentInstructions = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        Every section, for agents that cannot select an execution variant at runtime.
      '';
      default = cfg.common.base + cfg.common.sandbox-detection + cfg.common.sandbox + cfg.common.no-sandbox;
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
