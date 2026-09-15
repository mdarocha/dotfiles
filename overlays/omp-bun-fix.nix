# Self-expiring workaround for numtide/llm-agents.nix#7841 (oven-sh/bun#31023):
# omp compiles into a pristine, unpatched Bun 1.3.14 release binary because
# patchelf-touched Bun binaries corrupted standalone executables before Bun
# 1.4.0. nixpkgs' own `bun` is already >= 1.4.0, so swap that pristine
# template for the regular, patched `bun` this overlay chain provides.
final: prev:
let
  inherit (prev) lib;
  omp = prev.llm-agents.omp;
  oldRuntimeVersion = "1.3.14";
  marker = "-omp-bun-runtime-template-";

  patchLine =
    line:
    if lib.hasInfix marker line then
      let
        m = builtins.match ''(.*)"(/nix/store/[^"]*)"(.*)'' line;
      in
      if m == null then
        throw "overlays/omp-bun-fix.nix: expected a quoted bun-runtime-template path on this omp buildPhase line: ${line}"
      else
        (builtins.elemAt m 0) + ''"${final.bun}/bin/bun"'' + (builtins.elemAt m 2)
    else
      line;

  fixedBuildPhase =
    let
      patched = lib.concatStringsSep "\n" (map patchLine (lib.splitString "\n" omp.buildPhase));
    in
    if patched == omp.buildPhase then
      throw ''
        overlays/omp-bun-fix.nix no longer finds the pristine-Bun-template
        workaround in pkgs.llm-agents.omp's buildPhase — numtide/llm-agents.nix
        appears to have fixed llm-agents.nix#7841 upstream. Delete this file and
        its entry in flake-modules/home-configurations.nix, and drop the
        un-followed `llm-agents` nixpkgs input in flake.nix.
      ''
    else
      patched;

  fixedInstallCheckPhase =
    let
      patched = lib.replaceStrings [ ''"${oldRuntimeVersion}"'' ] [ ''"${final.bun.version}"'' ] omp.installCheckPhase;
    in
    if patched == omp.installCheckPhase then
      throw ''
        overlays/omp-bun-fix.nix no longer finds the hardcoded "${oldRuntimeVersion}"
        Bun-version check in pkgs.llm-agents.omp's installCheckPhase — its expected
        runtime version constant changed upstream. Delete this file and its entry in
        flake-modules/home-configurations.nix, and drop the un-followed `llm-agents`
        nixpkgs input in flake.nix.
      ''
    else
      patched;
in
{
  llm-agents = prev.llm-agents // {
    omp = omp.overrideAttrs (_: {
      buildPhase = fixedBuildPhase;
      installCheckPhase = fixedInstallCheckPhase;
    });
  };
}
