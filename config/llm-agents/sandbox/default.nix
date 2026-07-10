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

  # Python environment for OMP's eval tool. jupyter_kernel_gateway is added
  # to pkgs.python3Packages via the repo's nixpkgs overlay.
  pythonEvalEnv = pkgs.python3.withPackages (ps: [
    ps.ipykernel
    ps.jupyter_kernel_gateway
  ]);

  # Chromium wrapper that imports the sandbox proxy CA into Chromium's NSS
  # cert store before launch. The proxy is a TLS-intercepting MITM whose CA
  # is trusted by Node/curl via NODE_EXTRA_CA_CERTS / SSL_CERT_FILE, but
  # Chromium uses its own NSS database (~/.pki/nssdb) and ignores those vars.
  # Importing the cert here keeps full certificate verification intact — only
  # the proxy CA is trusted, not arbitrary certs. The sandbox $HOME is an
  # ephemeral tmpfs, so the DB is recreated fresh each session with the
  # correct per-session CA. No-ops gracefully when the cert file is absent
  # (i.e. when no allowedDomains is set and no proxy is running).
  #
  # --no-sandbox: Chromium tries to create its own inner sandbox via a second
  #   layer of user namespaces. That nested-namespace creation is blocked
  #   inside bwrap's user namespace. The flag disables Chromium's sandbox;
  #   security is still provided by the surrounding bwrap sandbox.
  # --disable-dev-shm-usage: bwrap gives the sandbox a fresh /tmp tmpfs and a
  #   minimal /dev, so /dev/shm may be absent or very small. This flag makes
  #   Chromium write shared memory blobs to /tmp instead, avoiding crashes.
  chromiumWrapper = pkgs.writeShellScriptBin "chromium" ''
    if [ -f /tmp/sandbox-ca-cert.pem ]; then
      NSS_DB="$HOME/.pki/nssdb"
      if [ ! -d "$NSS_DB" ]; then
        mkdir -p "$NSS_DB"
        ${pkgs.nss.tools}/bin/certutil -d "sql:$NSS_DB" -N --empty-password 2>/dev/null
      fi
      ${pkgs.nss.tools}/bin/certutil -d "sql:$NSS_DB" -A \
        -n "sandbox-proxy-ca" -t "C,," \
        -i /tmp/sandbox-ca-cert.pem 2>/dev/null || true
    fi
    exec ${pkgs.chromium}/bin/chromium --no-sandbox --disable-dev-shm-usage "$@"
  '';

  # Directories the sandboxed agent may read and write. Shared across omp and copilot-cli.
  sharedRwDirs = [
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

    # Rust / Cargo registry and build cache
    "$HOME/.cargo"
    "$HOME/.rustup"

    # Private NuGet artifact feeds.
    "$HOME/.nuget"
    "$HOME/.dotnet"
    "$HOME/.local/share/MicrosoftCredentialProvider"
    "$HOME/.local/.IdentityService"
    "$HOME/.microsoft/usersecrets"
  ];

  wrapWithSandbox =
    name: pkg:
    agentSandbox.mkSandbox {
      inherit pkg;
      binName = name;
      outName = name;

      allowedPackages = cfg.sandbox.allowedPackages;

      allowNix = true;
      # Bind system nix config read-only so the agent inherits experimental
      # features (nix-command, flakes) and substituter/registry settings.
      roFiles = [ "/etc/nix/nix.conf" ];

      rwDirs = sharedRwDirs;

      allowedDomains = lib.flatten (lib.attrValues cfg.sandbox.allowedDomainGroups);

      env = {
        # Used by karma-chrome-launcher when running Angular unit tests.
        CHROME_BIN = "${chromiumWrapper}/bin/chromium";
        # Used by Puppeteer (OMP browser tools). Point directly at the
        # Nix-provided binary so Puppeteer never tries to download Chrome.
        PUPPETEER_EXECUTABLE_PATH = "${chromiumWrapper}/bin/chromium";
        PUPPETEER_SKIP_DOWNLOAD = "true";
        # Puppeteer connects to Chrome's DevTools endpoint on 127.0.0.1
        # (sandbox-local loopback, isolated from the host). Without these,
        # Bun routes the WebSocket upgrade through HTTP_PROXY, which returns
        # 403 for 127.0.0.1 because it is not in the allowlist.
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

  nosandboxVariant =
    name: pkg:
    pkgs.writeShellScriptBin "${name}-nosandbox" ''
      exec ${pkg}/bin/${name} "$@"
    '';

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
        description = "Allowed outbound domains, grouped for display in agent instructions. Entries are bare domains; the proxy matches by suffix so 'foo.com' also covers any *.foo.com subdomain.";
        default = {
          "GitHub" = [
            "github.com"
            "githubusercontent.com"
          ];
          "GitHub Copilot" = [
            "githubcopilot.com"
          ];
          "npm" = [
            "npmjs.org"
            "npmjs.com"
            "yarnpkg.com"
            "fontawesome.com"
          ];
          "Python" = [
            "pypi.org"
            "python.org"
            "pythonhosted.org"
          ];
          "Nix" = [
            "nixos.org"
            "numtide.com"
            "cachix.org"
            "determinate.systems"
            "devenv.sh"
          ];
          "Rust" = [
            "crates.io"
          ];
          "Azure DevOps" = [
            "dev.azure.com"
            "visualstudio.com"
            "vsassets.io"
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
            "mdn.mozilla.net"
          ];
          "Model metadata" = [ "models.dev" ];
          "NuGet" = [ "api.nuget.org" ];
          "Figma" = [
            "figma.com"
          ];
          "Contentful" = [
            "contentful.com"
            "ctfassets.net"
          ];
        };
      };

      allowedPackages = mkOption {
        type = types.listOf types.package;
        description = "Packages placed on PATH inside the agent sandbox. Add any tool the agent needs to invoke.";
        default = with pkgs; [
          git
          gh
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
          chromiumWrapper
          cargo
          rustc
          rustfmt
          clippy
          # binutils: strings, objdump — binary inspection
          binutils
          # file: file-type detection
          file
          # procps: ps, pgrep, pkill — process inspection
          procps
        ];
      };

      wrapPackages = mkOption {
        type = types.functionTo (types.functionTo (types.listOf types.package));
        internal = true;
        readOnly = true;
        default = name: pkg: [
          (maybeSandbox name pkg)
          (nosandboxVariant name pkg)
        ];
        description = "Function to wrap a package binary with the sandbox and also produce an unsandboxed variant named <name>-nosandbox.";
      };
    };
  };
}
