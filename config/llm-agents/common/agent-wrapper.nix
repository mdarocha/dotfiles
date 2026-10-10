{
  pkgs,
  lib,
  environment,
}:

let
  netlog = pkgs.callPackage ./network-log { };
in
# Runs an agent with the shared PATH/env behind agent-netlog.
{
  name,
  program,
  preExec ? "",
}:
pkgs.writeShellScriptBin name ''
  export PATH="${lib.makeBinPath environment.path}:$PATH"
  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") environment.env
  )}
  ${preExec}
  exec ${lib.getExe netlog} "$HOME/.omp/network-log" ${name} ${program} "$@"
''
