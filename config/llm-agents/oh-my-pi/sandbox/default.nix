{
  pkgs,
  lib,
  inputs,
}:

let
  agentSandbox = inputs.agent-sandbox.lib.${pkgs.stdenv.hostPlatform.system};

  binName = "omp";
  omp = pkgs.writeShellScriptBin binName ''
    export PI_PROXY="$HTTPS_PROXY"
    exec ${pkgs.llm-agents.omp}/bin/${binName} "$@"
  '';

  python = import ./python.nix { inherit pkgs; };
  chromium = import ./chromium.nix { inherit pkgs; };
  tools = import ./packages.nix {
    inherit pkgs lib chromium;
    pythonEnv = python.env;
  };
  domains = import ./domains.nix { inherit lib; };
  paths = import ./paths.nix { inherit lib; };

  # Resolved at runtime by the wrapper's bash script (paths here are shell
  # strings, not Nix values) since the desktop user's uid varies per machine.
  waylandRuntimeDir = "/run/user/$(id -u)";
  waylandDisplay = "wayland-0";
  waylandSocketPath = "${waylandRuntimeDir}/${waylandDisplay}";

  sandboxedPackage = agentSandbox.mkSandbox {
    pkg = omp;
    inherit binName;
    outName = binName;

    allowedPackages = tools.list;
    allowedDomains = domains.allowed;

    allowNix = true;
    allowGpu = true;

    inherit (paths) rwDirs rwFiles;

    # Bind system nix config read-only so the agent inherits experimental
    # features (nix-command, flakes) and substituter/registry settings.
    roFiles = [ "/etc/nix/nix.conf" ] ++ paths.roFiles;
    roDirs = [ waylandSocketPath ] ++ paths.roDirs;

    env = {
      # Lets the instruction extension detect sandboxed vs. -nosandbox
      # execution without relying on fragile process-name introspection.
      MDAROCHA_AGENT_SANDBOX = "1";
      # Used by karma-chrome-launcher when running Angular unit tests.
      CHROME_BIN = "${chromium}/bin/chromium";
      # Used by Puppeteer (OMP browser tools). Point directly at the
      # Nix-provided binary so Puppeteer never tries to download Chrome.
      PUPPETEER_EXECUTABLE_PATH = "${chromium}/bin/chromium";
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
      # Setting VIRTUAL_ENV to this Nix-built env causes the OMP runtime to
      # prepend its bin/ to PATH, making `python3 -m kernel_gateway` and
      # `ipykernel` available without any pip install step at runtime.
      VIRTUAL_ENV = "${python.env}";
      # Expose to allow clipboard access
      WAYLAND_DISPLAY = waylandDisplay;
      XDG_RUNTIME_DIR = waylandRuntimeDir;
      # Evaluated on the host, where `gh` already has keyring access.
      GH_TOKEN = "$(${pkgs.gh}/bin/gh auth token)";
    };
  };

  # Same toolset and Python environment as the sandboxed variant, just
  # without the bwrap layer around it.
  hostPackage = pkgs.writeShellScriptBin "${binName}-nosandbox" ''
    export PATH="${lib.makeBinPath tools.list}:$PATH"
    export VIRTUAL_ENV="${python.env}"
    export CHROME_BIN="${chromium}/bin/chromium"
    export PUPPETEER_EXECUTABLE_PATH="${chromium}/bin/chromium"
    export PUPPETEER_SKIP_DOWNLOAD="true"

    exec ${pkgs.llm-agents.omp}/bin/${binName} "$@"
  '';
in
{
  package = sandboxedPackage;
  package-nosandbox = hostPackage;

  inherit (paths) ensureDirs;

  instructions = import ./instructions.nix {
    inherit lib;
    packageNames = tools.names;
    pythonPackageNames = python.packageNames;
    domainList = domains.markdownList;
  };
}
