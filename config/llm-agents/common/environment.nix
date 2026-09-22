{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  python = import ./environment/python.nix { inherit pkgs; };
  chromium = import ./environment/chromium.nix { inherit pkgs; };
  tools = import ./environment/packages.nix {
    inherit pkgs lib chromium;
    pythonEnv = python.env;
  };

  inlineNames = names: lib.concatMapStringsSep ", " (n: "`${n}`") names;

  instructions =
    builtins.replaceStrings
      [ "@packages@" "@pythonPackages@" ]
      [
        (inlineNames tools.names)
        (inlineNames python.packageNames)
      ]
      (builtins.readFile ./environment/toolset.md);
in
{
  options.mdarocha.llm-agents.environment = {
    path = mkOption {
      type = types.listOf types.package;
      default = tools.list;
      description = "Packages placed on PATH for every configured coding agent, sandboxed or not.";
    };

    env = mkOption {
      type = types.attrsOf types.str;
      default = {
        # Tools that respect $VIRTUAL_ENV (editors, venv-detection, and
        # OMP's own runtime PATH-prepending) pick up the Nix-built env.
        VIRTUAL_ENV = "${python.env}";
        CHROME_BIN = "${chromium}/bin/chromium";
        PUPPETEER_EXECUTABLE_PATH = "${chromium}/bin/chromium";
        PUPPETEER_SKIP_DOWNLOAD = "true";
      };
      description = "Environment variables exported alongside `path` for every configured coding agent.";
    };

    instructions = mkOption {
      type = types.str;
      default = instructions;
      description = "Toolset instructions describing `path`'s provisioned binaries and Python packages.";
    };
  };
}
