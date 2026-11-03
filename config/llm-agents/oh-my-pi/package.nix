# Workaround for omp > 18.13.2 failing to build in llm-agents:
# https://github.com/numtide/llm-agents.nix/pull/11552
# Drop once llm-agents ships omp >= 18.16.0.
{
  lib,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  unzip,
  bun,
  llm-agents,
}:

let
  version = "18.16.0";

  # omp needs bun >= 1.4.4, newer than nixpkgs'; compile onto upstream's unpatched binary.
  bunBin = stdenvNoCC.mkDerivation rec {
    pname = "bun-bin";
    version = "1.4.4";
    src = fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
      hash = "sha256-4ERutVmVdy65iUvrrppr42jZhai5Jx7hJEhvmUbu3XY=";
    };
    nativeBuildInputs = [ unzip ];
    dontFixup = true;
    installPhase = ''
      install -Dm755 bun $out/bin/bun
    '';
  };

  src = fetchFromGitHub {
    owner = "can1357";
    repo = "oh-my-pi";
    tag = "v${version}";
    hash = "sha256-hnb0yuRuuBY/DK+bLUNKFQkmBfPfAN67xOrycDL6OmA=";
  };
in
llm-agents.omp.overrideAttrs (old: {
  inherit version src;

  cargoDeps = rustPlatform.fetchCargoVendor {
    name = "omp-${version}-cargo-vendor";
    inherit src;
    hash = "sha256-YSPBniKcmTXhcI5A8tO90AyrBkY3J2PYlmVlDDnJlHU=";
  };

  env = old.env // {
    BUN_COMPILE_EXECUTABLE_PATH = "${bunBin}/bin/bun";
  };

  # llm-agents' compile wrapper doesn't pass the runtime path as an option.
  postPatch = old.postPatch + ''
    substituteInPlace packages/coding-agent/scripts/compile-binary.ts \
      --replace-fail options.executablePath process.env.BUN_COMPILE_EXECUTABLE_PATH
  '';

  # build-tool-views.ts is gone; the HTML export viewer is committed prebuilt.
  buildPhase =
    let
      toolViews = ''
        # export/html/index.ts text-imports ./tool-views.generated.js, which must
        # exist before bun compile.
        echo "Generating embedded HTML-export tool-views..."
        bun --cwd packages/collab-web scripts/build-tool-views.ts
      '';
    in
    assert lib.hasInfix toolViews old.buildPhase;
    lib.replaceStrings [ toolViews ] [ "" ] old.buildPhase;

  installCheckPhase = lib.replaceStrings [ bun.version ] [ bunBin.version ] old.installCheckPhase;
})
