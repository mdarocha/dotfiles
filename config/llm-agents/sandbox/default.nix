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

  patched-sandbox-runtime = pkgs.llm-agents.sandbox-runtime.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.gnupatch ];
    postInstall = (old.postInstall or "") + ''
      # Implement allowLocalBinding on Linux. Upstream only wires it for macOS
      # (Seatbelt). On Linux, bwrap --unshare-net creates an isolated network
      # namespace so bound ports are invisible from the host. This patch adds a
      # reverse socat bridge (host TCP:4096 <-> Unix socket <-> sandbox
      # TCP:localhost:4096) mirroring the existing outbound proxy architecture.
      # See: https://github.com/anthropic-experimental/sandbox-runtime/issues/165
      patch -p1 -d $out < ${./patches/srt-implement-allowlocalbinding-linux.patch}

      # Fix dangerous_files path resolution and ghost mount-point avoidance.
      # Upstream resolves all DANGEROUS_FILES relative to cwd, but shell configs
      # (.bashrc, .gitconfig, etc.) belong in $HOME — always denied there.
      # CWD files/dirs use git-ignore to decide: gitignored paths are always
      # denied (even non-existent); tracked paths only denied when they exist
      # (avoids ghost mount-point files for intentionally tracked content).
      patch -p1 -d $out < ${./patches/srt-fix-dangerous-files-paths.patch}
    '';
  });

  cfg = config.mdarocha.llm-agents;

  anthropic-sandbox-runtime-settings = {
    filesystem = {
      # Broad denies as recommended by sandbox-runtime README.
      # Fixed upstream in 0.0.46: --tmpfs on an ancestor no longer
      # clobbers --bind mounts for allowWrite paths underneath it.
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
        "~/.omp"
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
        "~/.omp"
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
      # TODO: The reverse bridge hardcodes port 4096 — only one sandboxed
      # instance can expose a local port at a time. Implement dynamic port
      # allocation (pick a free host port, pass it through to the sandbox).
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

        # Model metadata
        "models.dev"
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
