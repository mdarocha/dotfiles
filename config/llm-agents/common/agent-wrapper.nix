{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config.mdarocha.llm-agents) environment;

  netlog = pkgs.callPackage ./network-log { };

  logDirName = "network-log";
in
{
  options.mdarocha.llm-agents = {
    wrapper = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      readOnly = true;
      description = ''
        Builds an agent binary: `{ name, home, program, preExec ? "" }` runs `program`
        with the shared PATH/env behind agent-netlog, logging to
        `~/<home>/network-log` where `home` is the agent's home directory
        relative to `$HOME` (e.g. `.claude`).
      '';
      default =
        {
          name,
          home,
          program,
          preExec ? "",
        }:
        pkgs.writeShellScriptBin name ''
          export PATH="${lib.makeBinPath environment.path}:$PATH"
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") environment.env
          )}
          ${preExec}
          exec ${lib.getExe netlog} "$HOME/${home}/${logDirName}" ${name} ${program} "$@"
        '';
    };

    networkLogInstructions = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      readOnly = true;
      description = "Takes an agent's home directory relative to `$HOME` and returns instructions describing its network log.";
      default =
        home: builtins.replaceStrings [ "@dir@" ] [ "~/${home}/${logDirName}" ] (builtins.readFile ./network-log.md);
    };
  };
}
