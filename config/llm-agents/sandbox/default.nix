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

  cfg = config.mdarocha.llm-agents;

  anthropic-sandbox-runtime-settings = {
    filesystem = {
      denyRead = [
        "/home"
        "/var"
        "/etc/shadow"
        "/etc/gshadow"
        "/etc/sudoers"
        "/etc/sudoers.d"
        "/etc/ssh"
        "/etc/ssl/private"
        "/etc/security"
      ];
      allowRead = [
        "."
        "~/.local/share/opencode"
        "~/.config/opencode"
        "~/.config/gh"
        "~/.config/git"
        "~/.cache/nix-index"
      ];
      allowWrite = [
        "."
        "/tmp"
        "~/.local/share/opencode"
      ];
      denyWrite = [ ];
    };
    network = {
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
        makeBinaryWrapper ${getExe' pkgs.llm-agents.sandbox-runtime "srt"} $out/bin/${name} \
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
      pkgs.llm-agents.sandbox-runtime
    ];

    home.file.".srt-settings.json" = mkIf cfg.sandbox.enable {
      text = builtins.toJSON anthropic-sandbox-runtime-settings;
    };
  };
}
