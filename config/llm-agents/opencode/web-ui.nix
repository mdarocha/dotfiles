# Builds the opencode web UI and patched CLI binary from source.
#
# Upstream `opencode web` proxies all frontend assets from app.opencode.ai
# at runtime. We patch server.ts to use Hono's serveStatic instead, serving
# a locally-built copy of the SPA from OPENCODE_WEB_DIR.
{ pkgs }:

let
  version = pkgs.llm-agents.opencode.version;

  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    rev = "v${version}";
    hash = "sha256-JQsccVflS/GAjzguvZTLn7UH7tsou8yCSlaA48DVY10=";
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
    outputHash = "sha256-PRi466RTfKTG2f94iqqC14jARIJ9p9/QpK/i6FoB3eE=";

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

  # SolidJS + Vite SPA built from the prepared source tree.
  webUi = pkgs.stdenv.mkDerivation {
    pname = "opencode-web-ui";
    inherit version;
    src = sourceDeps;

    nativeBuildInputs = with pkgs; [ bun nodejs ];

    buildPhase = ''
      ${prepareBunSource}
      bun run --cwd packages/app build
    '';

    installPhase = ''
      cp -r packages/app/dist $out
    '';
  };

  # Patched opencode binary compiled from source.
  # Regular derivation (not FOD) since the output links against glibc.
  patched = pkgs.stdenv.mkDerivation {
    pname = "opencode-patched";
    inherit version;
    src = sourceDeps;

    patches = [ ./patches/opencode-serve-local-web-ui.patch ];

    nativeBuildInputs = with pkgs; [ bun nodejs ];

    env = {
      OPENCODE_VERSION = version;
      OPENCODE_CHANNEL = "latest";
    };

    buildPhase = ''
      ${prepareBunSource}

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
  };

in
{
  opencode-web-ui = webUi;
  opencode-patched = patched;
}
