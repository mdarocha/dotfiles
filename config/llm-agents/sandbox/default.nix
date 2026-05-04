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

    # Caches
    "$HOME/.npm"
    "$HOME/.cache/nix"
    "$HOME/.cache/nix-index"
    "$HOME/.cache/puppeteer"

    # Private NuGet artifact feeds.
    "$HOME/.nuget"
    "$HOME/.dotnet"
    "$HOME/.local/share/MicrosoftCredentialProvider"
    "$HOME/.local/.IdentityService"
    "$HOME/.microsoft/usersecrets"

    # Nix daemon Unix socket and config.
    # We expose the it so the nix binary inside the sandbox can connect to the host daemon.
    # TODO
    #"/nix/var/nix/daemon-socket"
    #"/etc/nix"

    # Full Nix store read access. mkSandbox only supports rw bind-mounts
    # (stateDirs); /nix/store is world-readable and root-owned so the sandbox
    # cannot write to it in practice.
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
          "Azure DevOps" = [
            "dev.azure.com"
            "*.dev.azure.com"
            "*.visualstudio.com"
            "*.vsassets.io"
            "login.microsoftonline.com"
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
          python3
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
