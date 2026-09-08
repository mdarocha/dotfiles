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
  tools = import ./tools.nix { inherit pkgs; };
  inherit (tools) pythonEvalPackageNames pythonEvalEnv chromiumWrapper;

  # Normalizes a domain group value to an attrset of domain → methods.
  # A plain list of domain strings becomes { domain = "*"; … }; an explicit
  # attrset (domain → "*" | ["GET" …]) is passed through unchanged.
  normalizeDomainGroup =
    value:
    if builtins.isList value then
      builtins.listToAttrs (
        map (d: {
          name = d;
          value = "*";
        }) value
      )
    else
      value;

  agentSandbox = inputs.agent-sandbox.lib.${pkgs.stdenv.hostPlatform.system};


  # Directories the sandboxed agent may read and write, shared across all
  # agents. ensureAgentSandboxDirs (below) creates any that are missing so a
  # freshly synced machine doesn't hard-fail at sandbox launch —
  # agent-sandbox.nix requires every declared rwDir / rwFile to already exist.
  sharedRwDirs = [
    "$HOME/.omp"
    "$HOME/.copilot"
    "$HOME/.config/gh"

    # Nix user config and profile state, so nix commands (registry, config,
    # nix-env) persist their state across sandbox runs.
    "$HOME/.config/nix"
    "$HOME/.local/state/nix"

    "$HOME/.npm"
    "$HOME/.bun/install/cache"
    "$HOME/.cache/nix"
    "$HOME/.cache/nix-index"
    "$HOME/.cache/direnv"
    "$HOME/.cargo"
    "$HOME/.rustup"

    # Private NuGet artifact feeds.
    "$HOME/.nuget"
    "$HOME/.dotnet"
    "$HOME/.local/share/MicrosoftCredentialProvider"
    "$HOME/.local/.IdentityService"
    "$HOME/.microsoft/usersecrets"
  ];

  sharedRwFiles = [
    "$HOME/.npmrc"
    "$HOME/.bunfig.toml"
  ];

  # Read-only dirs/files bound into the sandbox. Host-owned paths under $HOME
  # are pre-created by ensureAgentSandboxDirs below, same as sharedRwDirs /
  # sharedRwFiles. System paths outside $HOME (e.g. /etc/nix/nix.conf) and
  # runtime sockets (waylandSocketPath) are expected to already exist and are
  # bound directly in wrapWithSandbox instead.
  sharedRoDirs = [
    "$HOME/.config/direnv"
    "$HOME/.local/share/direnv"
    "$HOME/.config/git"
  ];

  sharedRoFiles = [ ];

  # Standard single-user-desktop location, exposed in sandbox to allow clipboard access
  waylandRuntimeDir = "/run/user/1000";
  waylandDisplay = "wayland-0";
  waylandSocketPath = "${waylandRuntimeDir}/${waylandDisplay}";

  wrapWithSandbox =
    name: pkg:
    agentSandbox.mkSandbox {
      inherit pkg;
      binName = name;
      outName = name;

      allowedPackages = cfg.sandbox.allowedPackages;

      allowNix = true;
      allowGpu = true;
      # TODO files should be an option
      # In general, this whole sandbox should probably be rewritten as a home-manager module
      # Bind system nix config read-only so the agent inherits experimental
      # features (nix-command, flakes) and substituter/registry settings.
      # Git identity config is also bound read-only (not a rwDir) so the
      # agent can't plant core.hooksPath / alias.* entries that would fire
      # host-side code on the next host `git` invocation — see the upstream
      # README's "Git identity" section.
      roFiles = [ "/etc/nix/nix.conf" ] ++ sharedRoFiles;
      roDirs = [ waylandSocketPath ] ++ sharedRoDirs;

      rwDirs = sharedRwDirs;
      rwFiles = sharedRwFiles;

      allowedDomains =
        let
          merged = builtins.foldl' (acc: v: acc // normalizeDomainGroup v) { } (
            lib.attrValues cfg.sandbox.allowedDomainGroups
          );
        in
        if cfg.sandbox.allowGetAnywhere then
          merged
          // {
            "*" = [
              "GET"
              "HEAD"
            ];
          }
        else
          merged;

      env = {
        # Lets agent instructions detect sandboxed vs. -nosandbox execution
        # without relying on fragile process-name introspection.
        MDAROCHA_AGENT_SANDBOX = "1";
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
        # Expose to allow clipboard access
        WAYLAND_DISPLAY = waylandDisplay;
        XDG_RUNTIME_DIR = waylandRuntimeDir;
      };
    };

  # PATH containing every sandbox tool's bin directory, prepended onto PATH
  # for the -nosandbox variant so it has access to the same toolset as the
  # sandboxed variant (see nosandboxVariant below).
  sandboxToolsPath = lib.makeBinPath cfg.sandbox.allowedPackages;

  # TODO this should not get created if the sandbox is disabled
  nosandboxVariant =
    name: pkg:
    pkgs.writeShellScriptBin "${name}-nosandbox" ''
      export PATH="${sandboxToolsPath}:$PATH"
      # Mirrors the sandboxed VIRTUAL_ENV wiring (see wrapWithSandbox above)
      # so OMP's eval tool can find the Nix-built Python environment
      # (ipykernel, kernel_gateway, …) even where the PATH prepend alone
      # isn't enough for OMP to discover it.
      export VIRTUAL_ENV="${pythonEvalEnv}"
      export CHROME_BIN="${chromiumWrapper}/bin/chromium"
      export PUPPETEER_EXECUTABLE_PATH="${chromiumWrapper}/bin/chromium"
      export PUPPETEER_SKIP_DOWNLOAD="true"

      exec ${pkg}/bin/${name} "$@"
    '';

  maybeSandbox = name: pkg: if cfg.sandbox.enable then wrapWithSandbox name pkg else pkg;
in
{
  imports = [ ./network.nix ];
  options.mdarocha.llm-agents = {
    sandbox = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to wrap llm-agent tools with bubblewrap (Linux) or Seatbelt (macOS) via agent-sandbox.nix.";
      };

      allowedPackages = mkOption {
        type = types.listOf types.package;
        description = "Packages placed on PATH inside the agent sandbox. Add any tool the agent needs to invoke.";
        default = tools.allowedPackages;
      };

      packageDescriptions = mkOption {
        type = types.listOf types.str;
        internal = true;
        readOnly = true;
        description = "Human-readable names of sandbox packages, auto-derived for agent instructions.";
        default =
          let
            cleanName =
              raw:
              let
                # Strip "-wrapper" suffix (e.g. binutils-wrapper → binutils)
                s1 = lib.removeSuffix "-wrapper" raw;
                # Strip version-env suffix (e.g. python3-3.14.6-env → python3)
                s2 =
                  let
                    m = builtins.match "(.+)-[0-9].*" s1;
                  in
                  if m != null then builtins.head m else s1;
              in
              s2;
            getName =
              p:
              if p ? pname then
                cleanName p.pname
              else if p ? name then
                cleanName p.name
              else
                null;
          in
          builtins.filter (n: n != null) (map getName cfg.sandbox.allowedPackages);
      };

      pythonPackageNames = mkOption {
        type = types.listOf types.str;
        internal = true;
        readOnly = true;
        description = "Python package names available in the sandbox eval environment, auto-derived for agent instructions.";
        default = pythonEvalPackageNames;
      };

      # TODO this should have better typing than just attrsOf
      wrapPackages = mkOption {
        type = types.functionTo (types.functionTo (types.attrsOf types.package));
        internal = true;
        readOnly = true;
        default = name: pkg: {
          sandbox = (maybeSandbox name pkg);
          no-sandbox = (nosandboxVariant name pkg);
        };
        description = "Function to wrap a package binary with the sandbox and also produce an unsandboxed variant named <name>-nosandbox.";
      };
    };
  };

  config = lib.mkIf cfg.sandbox.enable {
    # agent-sandbox.nix hard-errors at launch if a declared rwDir / rwFile /
    # roDir / roFile is missing on the host. Create them here as a
    # home-manager activation step instead of relying on the sandbox library
    # to create them itself (upstream deliberately removed that: silently
    # creating agent-declared paths at every launch risks masking typos as
    # new state directories).
    # See https://github.com/archie-judd/agent-sandbox.nix/pull/72.
    home.activation.ensureAgentSandboxDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${lib.concatMapStringsSep " " (p: ''"${p}"'') (sharedRwDirs ++ sharedRoDirs)}
      mkdir -p ${
        lib.concatMapStringsSep " " (p: ''"${builtins.dirOf p}"'') (sharedRwFiles ++ sharedRoFiles)
      }
      for f in ${lib.concatMapStringsSep " " (p: ''"${p}"'') (sharedRwFiles ++ sharedRoFiles)}; do
        [ -e "$f" ] || touch "$f" || true
      done
    '';
  };
}
