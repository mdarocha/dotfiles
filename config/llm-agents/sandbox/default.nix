{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    getExe'
    mkIf
    mkOption
    types
    ;

  # Patch srt's bwrap argument ordering bug: when denyRead uses --tmpfs on an
  # ancestor of an allowWrite path (e.g. /var over ~/.cache/nix), the tmpfs
  # clobbers the earlier --bind mount. The "re-allow read" step then restores
  # access with --ro-bind, silently losing writability.
  # Fix: hoist allowedWritePaths and use --bind instead of --ro-bind for paths
  # that are also writable.
  # TODO upstream fix
  patched-sandbox-runtime = pkgs.llm-agents.sandbox-runtime.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.gnupatch ];
    postInstall = (old.postInstall or "") + ''
      # Fix bwrap argument ordering: --tmpfs on a denyRead ancestor clobbers
      # --bind mounts for allowWrite paths underneath it. Re-allows must use
      # --bind (rw) instead of --ro-bind for paths that are also writable.
      patch -p1 -d $out < ${./srt-fix-denyread-clobbers-allowwrite.patch}

      # Implement allowLocalBinding on Linux. Upstream only wires it for macOS
      # (Seatbelt). On Linux, bwrap --unshare-net creates an isolated network
      # namespace so bound ports are invisible from the host. This patch adds a
      # reverse socat bridge (host TCP:4096 <-> Unix socket <-> sandbox
      # TCP:localhost:4096) mirroring the existing outbound proxy architecture.
      # See: https://github.com/anthropic-experimental/sandbox-runtime/issues/165
      patch -p1 -d $out < ${./srt-implement-allowlocalbinding-linux.patch}

      # Fix dangerous_files path resolution and ghost mount-point pollution.
      # Upstream resolves all DANGEROUS_FILES relative to cwd, but shell configs
      # (.bashrc, .gitconfig, etc.) belong in $HOME.  This also skips files that
      # don't exist (avoids bwrap creating empty mount-point ghost files in cwd)
      # and skips cwd files that are git-tracked (not gitignored) since the user
      # intentionally put them there.
      patch -p1 -d $out < ${./srt-fix-dangerous-files-paths.patch}
    '';
  });

  cfg = config.mdarocha.llm-agents;

  anthropic-sandbox-runtime-settings = {
    filesystem = {
      # Broad denies as recommended by sandbox-runtime README.
      # Requires the patched-sandbox-runtime above — without the patch,
      # --tmpfs /var clobbers --bind mounts for allowWrite paths under
      # $HOME (/var/home/<user> on Fedora Atomic).
      denyRead = [
        "/home"
        "/var"
        "/run"
        "/etc/shadow"
        "/etc/gshadow"
        "/etc/sudoers"
        "/etc/sudoers.d"
        "/etc/ssh"
        "/etc/ssl/private"
        "/etc/security"
      ];
      allowRead = [
        "/nix"
        "."
        "~/.nix-profile"
        "~/.local/share/opencode"
        "~/.local/state/opencode"
        "~/.cache/opencode"
        "~/.config/opencode"
        "~/.config/gh"
        "~/.config/git"
        "~/.cache/nix"
        "~/.cache/nix-index"
      ];
      allowWrite = [
        "."
        "/tmp"
        "~/.cache/nix"
        "~/.local/share/opencode"
        "~/.local/state/opencode"
        "~/.cache/opencode"
      ];
      denyWrite = [ ];
    };
    network = {
      # Nix needs Unix sockets to communicate with the daemon.
      # On Linux, srt uses seccomp BPF to block socket(AF_UNIX, ...) at the syscall level,
      # so allowUnixSockets for specific paths doesn't help — the syscall is blocked
      # before connect(). We must disable the filter entirely.
      # On macOS, srt uses Seatbelt which can filter by path, so we can allowlist.
    }
    // (
      if pkgs.stdenv.isLinux then
        {
          allowAllUnixSockets = true;
        }
      else
        {
          allowUnixSockets = [
            "/nix/var/nix/daemon-socket/socket"
          ];
        }
    )
    // {
      # Allow opencode web to bind to a local port and serve the web UI.
      allowLocalBinding = true;
      allowedDomains = [
        # GitHub
        "github.com"
        "*.github.com"
        "*.githubusercontent.com"

        # GitHub Copilot
        "*.githubcopilot.com"
        "default.exp-tas.com"

        # npm
        "registry.npmjs.org"
        "registry.npmjs.com"
        "npmjs.org"
        "npmjs.com"
        "registry.yarnpkg.com"
        "yarnpkg.com"

        # Python / pip
        "pypi.org"
        "pypi.python.org"
        "files.pythonhosted.org"
        "*.pythonhosted.org"

        # Nix
        "cache.nixos.org"
        "cache.numtide.com"
        "*.cachix.org"
        "install.determinate.systems"

        # Azure DevOps
        "dev.azure.com"
        "*.dev.azure.com"
        "*.visualstudio.com"
        "*.vsassets.io"
        "login.microsoftonline.com"

        # MCP tools
        "mcp.grep.app"
        "mcp.exa.ai"
      ];
      deniedDomains = [ ];
    };
  };

  wrapWithSandbox =
    name: pkg:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
      }
      ''
        mkdir -p $out/bin
        # -- separates srt flags from the wrapped command,
        # so that flags like --help are passed to the wrapped binary, not srt
        makeBinaryWrapper ${getExe' patched-sandbox-runtime "srt"} $out/bin/${name} \
          --add-flags -- \
          --add-flags ${getExe' pkg name}
      '';

  maybeSandbox = name: pkg: if cfg.sandbox.enable then wrapWithSandbox name pkg else pkg;
in
{
  options.mdarocha.llm-agents = {
    sandbox = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to wrap llm-agent tools with the Anthropic sandbox runtime (srt).";
      };

      wrapPackage = mkOption {
        type = types.functionTo (types.functionTo types.package);
        internal = true;
        readOnly = true;
        default = maybeSandbox;
        description = "Function to conditionally wrap a package binary with the sandbox runtime.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf cfg.sandbox.enable [
      patched-sandbox-runtime
    ];

    home.file.".srt-settings.json" = mkIf cfg.sandbox.enable {
      text = builtins.toJSON anthropic-sandbox-runtime-settings;
    };
  };
}
