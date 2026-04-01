# Builds the patched opencode CLI binary from source.
#
# We apply patches to add skill invocation control and auth hook
# merging, which require compiling from the TypeScript source.
{ pkgs, lib ? pkgs.lib }:

let
  version = pkgs.llm-agents.opencode.version;

  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    rev = "v${version}";
    hash = "sha256-hHyG1s/aaIDpZOF/ZGd0BgBK/DLHfsLZjbbYcYhbFeQ=";
  };

  # Bun needs writable HOME/XDG_CACHE_HOME. The FOD's node_modules contain
  # #!/usr/bin/env shebangs that must be patched to absolute nix store paths.
  # This can't happen in the FOD itself (would create store self-references
  # and break the output hash), so every downstream derivation runs it.
  prepareBunSource = ''
    export HOME=$(mktemp -d)
    export XDG_CACHE_HOME=$(mktemp -d)
    patchShebangs node_modules
  '';

  # Full monorepo source with node_modules installed (FOD -- needs network).
  # Outputs the entire tree including per-workspace node_modules that bun
  # creates, which are required for module resolution.
  sourceDeps = pkgs.stdenv.mkDerivation {
    pname = "opencode-source-deps";
    inherit version src;

    nativeBuildInputs = with pkgs; [ bun nodejs cacert ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-roZxay8RNs6iaxpSoKzFcKOqhOyS8111CuY5GqR+B9I=";

    dontFixup = true;

    buildPhase = ''
      export HOME=$(mktemp -d)
      export XDG_CACHE_HOME=$(mktemp -d)
      bun install --frozen-lockfile --ignore-scripts
    '';

    installPhase = ''
      cp -r . $out
    '';
  };

  # Patched opencode binary compiled from source.
  # Regular derivation (not FOD) since the output links against glibc.
  # autoPatchelfHook fixes the ELF interpreter and RPATH so the bun-compiled
  # binary finds glibc and libstdc++ from the nix store instead of relying
  # on the build-time paths baked in by bun's linker.
  patched = pkgs.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;
    src = sourceDeps;

    patches = [
      ./patches/opencode-merge-plugin-auth-hooks.patch
      ./patches/opencode-skill-invocation-control.patch
      ./patches/opencode-skill-invocation-context.patch
    ];

    nativeBuildInputs = with pkgs; [
      bun
      nodejs
      autoPatchelfHook
      makeBinaryWrapper
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
    ];

    # strip removes the compressed TypeScript code embedded by bun's compiler
    dontStrip = true;

    env = {
      OPENCODE_VERSION = version;
      OPENCODE_CHANNEL = "latest";
    };

    buildPhase = ''
      ${prepareBunSource}

      # The build script enforces bun >= 1.3.11 via semver check. Nixpkgs
      # may ship a slightly older patch version; the build itself works fine.
      substituteInPlace packages/script/src/index.ts \
        --replace-fail 'throw new Error(`This script requires bun' '// throw new Error(`This script requires bun'
      # Stub out the models.dev snapshot -- the build script fetches it from
      # the network which is unavailable here. At runtime opencode fetches
      # fresh model metadata from models.dev on startup, so the baked-in
      # snapshot only serves as a fallback. Must be a non-empty object so
      # the generated TypeScript (`export const snapshot = ... as const`)
      # parses correctly.
      echo -n '{"_stub":true}' > models-dev-stub.json
      export MODELS_DEV_API_JSON="$PWD/models-dev-stub.json"

      bun run --cwd packages/opencode build --single --skip-install
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp packages/opencode/dist/*/bin/opencode $out/bin/opencode
      chmod +x $out/bin/opencode
    '';

    # makeBinaryWrapper must run after autoPatchelfHook (which runs in fixupPhase),
    # otherwise the wrapper replaces the ELF before it can be patched.
    postFixup = ''
      mv $out/bin/opencode $out/bin/.opencode-wrapped
      makeBinaryWrapper $out/bin/.opencode-wrapped $out/bin/opencode \
        --set OPENCODE_ENABLE_EXA true \
        --prefix PATH : ${
          lib.makeBinPath (
            with pkgs;
            [
              fzf
              ripgrep
            ]
            ++ lib.optionals stdenv.isLinux [ wl-clipboard ]
          )
        }
    '';
  };

in
{
  opencode-patched = patched;
}
