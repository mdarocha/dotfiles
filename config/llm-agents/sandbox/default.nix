{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.mdarocha.llm-agents;

  # Instantiate agent-sandbox.nix for the current platform. The library
  # exposes per-system attrsets from its flake output so we index by
  # pkgs.system here rather than threading a second pkgs argument through.
  # TODO: this is ugly, improve
  agentSandbox = inputs.agent-sandbox.lib.${pkgs.stdenv.hostPlatform.system};

  # The proxy inside agent-sandbox.nix performs suffix-based domain matching:
  # "github.com" already covers api.github.com, raw.github.com, etc.
  # allowedDomains list uses "*.foo.com" prefixes which the proxy
  # does not interpret as wildcards — it would match literally. Strip all
  # leading "*." segments so every entry becomes the bare registrable domain.
  # TODO: fix this somehow
  stripWildcardPrefix =
    d: if lib.hasPrefix "*." d then stripWildcardPrefix (lib.removePrefix "*." d) else d;

  normalizedAllowedDomains = lib.unique (
    map stripWildcardPrefix (lib.flatten (lib.attrValues cfg.sandbox.allowedDomainGroups))
  );

  # Python environment for OMP's eval tool. jupyter_kernel_gateway is added
  # to pkgs.python3Packages via the repo's nixpkgs overlay.
  # openai-whisper is required for OMP's STT (speech-to-text) feature;
  # baking it in here avoids the broken `pip install` path at runtime.
  pythonEvalEnv = pkgs.python3.withPackages (ps: [
    ps.ipykernel
    ps.jupyter_kernel_gateway
    ps.openai-whisper
  ]);

  # Directories the sandboxed agent may read and write. All paths are
  # bind-mounted read-write (agent-sandbox.nix has no separate read-only
  # stateDir concept). Shared across omp and copilot-cli.
  sharedStateDirs = [
    # Agent configs
    "$HOME/.omp"
    "$HOME/.copilot"

    # Misc configs
    "$HOME/.config/gh"
    "$HOME/.config/git"

    # Nix user config and profile state. Created if absent so nix commands
    # (registry, config, nix-env) persist their state across sandbox runs.
    "$HOME/.config/nix"
    "$HOME/.local/state/nix"

    # npm / bun config and caches
    "$HOME/.npmrc"
    "$HOME/.npm"
    "$HOME/.bun/install/cache"
    "$HOME/.bunfig.toml"
    "$HOME/.cache/nix"
    "$HOME/.cache/nix-index"
    "$HOME/.cache/whisper"

    # Rust / Cargo registry and build cache
    "$HOME/.cargo"
    "$HOME/.rustup"

    # Private NuGet artifact feeds.
    "$HOME/.nuget"
    "$HOME/.dotnet"
    "$HOME/.local/share/MicrosoftCredentialProvider"
    "$HOME/.local/.IdentityService"
    "$HOME/.microsoft/usersecrets"

    # System Nix configuration. /etc/nix exists but is outside the default
    # sandbox mount tree; bind-mounting it lets the nix binary read
    # nix.conf, registry.json, machines, etc.
    "/etc/nix"

    # Full Nix store. mkSandbox only supports rw bind-mounts (stateDirs);
    # /nix/store is world-readable and root-owned so the sandbox cannot
    # write to it in practice. Mounting the whole store lets the nix binary
    # access any store path, including the Python eval environment below.
    "/nix/store"
  ];

  wrapWithSandbox =
    name: pkg:
    agentSandbox.mkSandbox {
      inherit pkg;
      binName = name;
      outName = name;
      allowedPackages = cfg.sandbox.allowedPackages;
      stateDirs = sharedStateDirs;
      restrictNetwork = true;
      allowedDomains = normalizedAllowedDomains;
      extraEnv = {
        # Used by karma-chrome-launcher when running Angular unit tests.
        CHROME_BIN = "${pkgs.chromium}/bin/chromium";
        # Used by Puppeteer (OMP browser tools). Point directly at the
        # Nix-provided binary so Puppeteer never tries to download Chrome.
        PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        PUPPETEER_SKIP_DOWNLOAD = "true";
        # Puppeteer connects to Chrome's DevTools endpoint on 127.0.0.1
        # (sandbox-local loopback, isolated from the host). Without these,
        # Bun routes the WebSocket upgrade through HTTP_PROXY, which returns
        # 403 for 127.0.0.1 because it is not in the allowlist.
        # 127.0.0.1 stays on `lo` inside the sandbox (ip route get 127.0.0.1
        # → dev lo) and cannot reach host services; host is only reachable
        # via 10.0.2.2 (pasta gateway), which remains proxy-filtered.
        NO_PROXY = "127.0.0.1,localhost";
        no_proxy = "127.0.0.1,localhost";
        # Chromium-based tests (e.g. Angular/Karma) call fontconfig to enumerate
        # fonts. Without a valid config file the sandbox sees no fonts and Chrome
        # aborts. Point at the Nix-provided fonts.conf so fontconfig initialises
        # correctly inside the sandbox.
        FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
        # Python eval environment for OMP's eval tool. Setting VIRTUAL_ENV to
        # this Nix-built env causes the OMP runtime to prepend its bin/ to PATH,
        # making `python3 -m kernel_gateway` and `ipykernel` available without
        # any pip install step at runtime.
        VIRTUAL_ENV = "${pythonEvalEnv}";
      };
    };

  maybeSandbox = name: pkg: if cfg.sandbox.enable then wrapWithSandbox name pkg else pkg;
in
{
  options.mdarocha.llm-agents = {
    sandbox = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to wrap llm-agent tools with bubblewrap (Linux) or Seatbelt (macOS) via agent-sandbox.nix.";
      };

      allowedDomainGroups = mkOption {
        type = types.attrsOf (types.listOf types.str);
        description = "Allowed outbound domains grouped by display label. Keys are category names shown in agent instructions; values are lists of domain patterns.";
        default = {
          "GitHub" = [
            "github.com"
            "*.github.com"
            "*.githubusercontent.com"
          ];
          "GitHub Copilot" = [
            "*.githubcopilot.com"
            "*.*.githubcopilot.com"
          ];
          "npm" = [
            "registry.npmjs.org"
            "registry.npmjs.com"
            "npmjs.org"
            "npmjs.com"
            "registry.yarnpkg.com"
            "yarnpkg.com"
            "api.npmjs.org"
            "npm.fontawesome.com"
            "dl.fontawesome.com"
          ];
          "Python" = [
            "pypi.org"
            "pypi.python.org"
            "files.pythonhosted.org"
            "*.pythonhosted.org"
          ];
          "Nix" = [
            "channels.nixos.org"
            "cache.nixos.org"
            "cache.numtide.com"
            "*.cachix.org"
            "install.determinate.systems"
          ];
          "Rust" = [
            "crates.io"
            "static.crates.io"
            "index.crates.io"
          ];
          "Azure DevOps" = [
            "dev.azure.com"
            "*.dev.azure.com"
            "*.visualstudio.com"
            "*.vsassets.io"
            "login.microsoftonline.com"
            "blob.core.windows.net"
          ];
          "MCP tools" = [
            "mcp.grep.app"
            "mcp.context7.com"
            "mcp.exa.ai"
            "websetsmcp.exa.ai"
            "api.exa.ai"
          ];
          "Documentation" = [
            "learn.microsoft.com"
            "developers.google.com"
            "docs.github.com"
          ];
          "Model metadata" = [ "models.dev" ];
          "NuGet" = [ "api.nuget.org" ];
          "Figma" = [
            "figma.com"
            "*.figma.com"
          ];
          "Contentful" = [
            "contentful.com"
            "*.contentful.com"
            "api.contentful.com"
            "cdn.contentful.com"
            "preview.contentful.com"
            "images.ctfassets.net"
            "*.ctfassets.net"
          ];
        };
      };

      allowedPackages = mkOption {
        type = types.listOf types.package;
        description = "Packages placed on PATH inside the agent sandbox. Add any tool the agent needs to invoke.";
        default = with pkgs; [
          git
          gh
          nix
          pythonEvalEnv
          nodejs
          bun
          coreutils
          findutils
          gnused
          gnugrep
          gawk
          curl
          jq
          ripgrep
          fd
          which
          diffutils
          chromium
          cargo
          rustc
          rustfmt
          clippy
          # ffmpeg: required for OMP voice mode (audio encode/decode)
          ffmpeg
        ];
      };

      wrapPackage = mkOption {
        type = types.functionTo (types.functionTo types.package);
        internal = true;
        readOnly = true;
        default = maybeSandbox;
        description = "Function to conditionally wrap a package binary with the sandbox.";
      };
    };
  };
}
