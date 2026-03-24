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
      patch -p1 -d $out < ${./srt-fix-denyread-clobbers-allowwrite.patch}
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
