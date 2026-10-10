{
  pkgs,
  lib,
  src,
}:

let
  manifest = lib.importJSON "${src}/package.json";
  lock = lib.importJSON "${src}/package-lock.json";

  # OMP rewrites `@earendil-works/*` imports onto its bundled copies; every
  # other peer (typebox) must ship alongside the extension.
  peers = lib.filter (name: !lib.hasPrefix "@earendil-works/" name) (
    lib.attrNames (manifest.peerDependencies or { })
  );

  isRuntime =
    path: entry:
    path != "" && (!(entry.dev or false) || lib.elem (lib.removePrefix "node_modules/" path) peers);

  modules = lib.mapAttrsToList (path: entry: {
    inherit path;
    tarball = pkgs.fetchurl {
      url = entry.resolved;
      hash = entry.integrity;
    };
  }) (lib.filterAttrs isRuntime lock.packages);
in
pkgs.runCommand "pi-automode-${manifest.version}" { } ''
  mkdir -p $out
  cp -r ${src}/package.json ${src}/extensions ${src}/skills $out/
  ${lib.concatMapStrings (module: ''
    mkdir -p $out/${module.path}
    tar -xzf ${module.tarball} -C $out/${module.path} --strip-components=1
  '') modules}
''
