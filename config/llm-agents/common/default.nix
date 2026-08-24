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
    agentInstructions = mkOption {
      type = types.str;
      description = "Common agent instructions injected as AGENTS.md for all configured agents.";
      default = ''
        ## Sandbox detection

        You may be running inside a sandboxed environment or directly on the host.
        **You MUST determine which mode you are in before relying on any sandbox-specific
        rule below.** Check the `MDAROCHA_AGENT_SANDBOX` environment variable once at
        session start:

        ```bash
        echo "$MDAROCHA_AGENT_SANDBOX"
        ```

        - `1` → you are **inside** the sandbox. All **(sandbox only)** rules apply.
        - unset/empty → you are **outside** the sandbox (the `-nosandbox` variant).
          Skip every section marked **(sandbox only)** — network is unrestricted,
          localhost reaches the host, and you manage dependencies yourself (pip, npm,
          etc.). The sandbox's tool list below is also on PATH here (see the note in
          that section), but it is not exhaustive — the host may provide more besides.

        ## Available CLI tools (sandbox only)

        Inside the sandbox, **only** the packages listed below are on PATH (plus `nix`
        itself). No other binaries are available. Do not assume tools exist — check this
        list first. If you need a tool not listed here, use `nix run nixpkgs#<package>`
        or `nix shell nixpkgs#<package>` to get it temporarily.

        ${lib.concatMapStringsSep ", " (n: "`${n}`") cfg.sandbox.packageDescriptions}

        The `-nosandbox` variant prepends this same tool list onto PATH, so every
        package above is available there too, on top of whatever else the host provides.

        ## Python execution environment (sandbox only)

        Python dependencies are **pre-installed by the sandbox** via a Nix-managed
        environment. The `eval` tool's Python kernel already has access to every
        provisioned package. You MUST NOT install packages at runtime — `pip install`,
        `uv pip install`, `pip install --user`, `python -m pip`, or any other package
        manager invocation will fail or produce results silently discarded when the
        session ends.

        This applies in the `-nosandbox` variant too — it points `VIRTUAL_ENV` at
        the same Nix-built environment, so `pip install` fails there identically.

        Pre-installed Python packages: ${lib.concatMapStringsSep ", " (n: "`${n}`") cfg.sandbox.pythonPackageNames}

        If a task requires a package not listed above:
        1. Tell the user which package is missing and that it must be added to the
           sandbox config (`pythonEvalEnv` in `config/llm-agents/sandbox/default.nix`).
        2. Do NOT work around the absence by downloading wheels, vendoring source, or
           running `pip` with `--target`.

        **WRONG:**
        ```python
        import subprocess
        subprocess.run(["pip", "install", "requests"])  # FAILS: no pip, no network to PyPI
        ```

        **RIGHT:**
        ```python
        import pandas as pd  # already available, just import it
        df = pd.read_csv("data.csv")
        ```

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

        Outside the sandbox (`-nosandbox`), direnv and devenv work normally if installed
        on the host.

        ## Network restrictions (sandbox only)

        Outbound network access is restricted by a filtering proxy. HTTP requests will
        fail with connection errors for any disallowed domain or method.

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

        ## Git LFS and `.git/config` (sandbox only)

        `.git/config` in a project checkout is **read-only** inside the sandbox — any
        write to it, e.g. `git config --local ...`, fails with "Device or resource
        busy" / "Read-only file system". This is not repo-specific; it applies to
        every checkout.

        Do **not** run `git lfs install`: LFS filters are already configured
        globally (`filter.lfs.*` in `~/.config/git/config`, provisioned by
        home-manager's `programs.git.lfs.enable`), and that file is also a
        read-only bind mount inside the sandbox, so `git lfs install` cannot write
        to it either and is unnecessary — `add`/`commit`/`push`/`checkout` already
        smudge/clean LFS-tracked files correctly without any per-repo
        `.git/config` entries. `git-lfs` itself is on `$PATH`.

        ## Browser GPU acceleration

        This applies identically inside the sandbox and in the `-nosandbox` variant.

        Detect whether the browser tool's Chromium is currently running headless
        (no GPU) or visible (real GPU, where available) by checking the live process
        — not any stored setting, which may not reflect what's actually running:

        ```bash
        ps aux | grep -o -- '--ozone-platform=headless' | head -1
        ```

        Non-empty output → headless mode. Chromium's `headless` Ozone platform forces
        SwiftShader (software) rendering unconditionally, so no GPU acceleration is
        possible regardless of `/dev/dri` access or driver env wiring. Empty output
        with a `libexec/chromium/chromium` process present → visible mode, with real
        GPU acceleration available wherever the sandbox/host provides it. No chromium
        process at all → the browser tool hasn't launched yet this session; mode is
        undetermined until first use.

        Confirm the actual GPU backend via `chrome://gpu`'s "Graphics Feature Status"
        and `GPU0` fields, not `WEBGL_debug_renderer_info` / `navigator.userAgent` —
        the browser tool spoofs those for fingerprinting resistance regardless of the
        real backend.

        If Chromium is running headless but the task genuinely needs GPU-backed
        rendering (e.g. WebGL correctness, GPU compute), headless mode cannot provide
        it — ask the user to switch the browser tool to visible/non-headless mode and
        relaunch it.

        ## WSL environment

        When running under WSL (Windows Subsystem for Linux), Windows filesystem paths
        are available under `/mnt/c`, `/mnt/d`, etc. You can read and write files on the
        Windows side directly — for example, `ls /mnt/c/Users` lists Windows user
        directories. Check for WSL by inspecting the kernel version:

        ```bash
        grep -qi microsoft /proc/version 2>/dev/null && echo "WSL" || echo "native"
        ```

        **Important:** `/mnt/c` is **not** available inside the sandbox. The sandbox
        isolates the filesystem — only explicitly bound directories are visible. If a
        task requires reading or writing Windows-side files, you must run in the
        `-nosandbox` variant, or ask the user to copy the files into the Linux filesystem
        first.

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

        No comment is the default. Well-named code is self-documenting, so a
        comment must earn its place by saying something the code genuinely cannot:
        a non-obvious *why*, a subtle edge case, a business rule invisible locally,
        or a workaround (link the issue). Everything else goes: restatements of the
        code, structural labels (`# imports`, `# helper`), phase headers
        (`// Step 1: validate`), decorative separators, summaries of the function
        they sit above, narration of the block below, edit history (`// changed
        from`, `// now handles`, `// new`), commented-out code, and anything tied
        to the current sandbox, host, or session rather than the code itself.
        Match the file's existing comment density — never raise it, and
        write edits as if the code had always been that way. Doc comments are the
        contract for the public surface, not every private helper: follow the file's
        convention, use the language's native format, document behavior, invariants,
        units, and error/panic conditions, and never restate a name and type
        (`@param id — the id`). When unsure, leave it out.

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

    rules = mkOption {
      type = types.attrsOf types.path;
      description = "Map of rule name to source path. Each rule is written to all configured agents.";
      default = {
        no-nix-store-source-search = ./rules/no-nix-store-source-search.md;
        no-filesystem-root-scan = ./rules/no-filesystem-root-scan.md;
        pr-fixes-one-per-line = ./rules/pr-fixes-one-per-line.md;
        minimal-comments = ./rules/minimal-comments.md;
      };
    };
  };
}
