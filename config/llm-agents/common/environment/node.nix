{ pkgs }:

let
  # Exact versions only. Bumping any entry changes the fixed-output hash.
  packages = {
    docx = "9.11.0";
    pptxgenjs = "4.0.1";
    react = "19.3.1";
    react-dom = "19.3.1";
    react-icons = "5.7.0";
    sharp = "0.35.5";
  };

  specs = pkgs.lib.mapAttrsToList (name: version: "${name}@${version}") packages;

  # Fixed-output so npm may use the network. The hash also pins the
  # transitive dependency tree resolved at install time.
  modules = pkgs.stdenvNoCC.mkDerivation {
    name = "agent-node-modules";

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.cacert
    ];

    dontUnpack = true;
    dontFixup = true;

    buildPhase = ''
      export HOME=$TMPDIR
      npm install --prefix $TMPDIR/prefix --no-save --no-package-lock \
        --ignore-scripts --no-audit --no-fund ${pkgs.lib.escapeShellArgs specs}
    '';

    installPhase = ''
      mkdir -p $out
      cp -r $TMPDIR/prefix/node_modules $out/node_modules
      rm -f $out/node_modules/.package-lock.json
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-2+/qpMgCW9uYofP/gGXq8k5b0ZaShLx5U+Fb9gDgpXE=";
  };
in
{
  inherit packages;

  nodePath = "${modules}/node_modules";
}
