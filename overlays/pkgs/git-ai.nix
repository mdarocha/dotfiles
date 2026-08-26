{
  lib,
  rustPlatform,
  gitAiSrc,
  pkg-config,
  sqlite,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "git-ai";
  version = (builtins.fromTOML (builtins.readFile "${gitAiSrc}/Cargo.toml")).package.version;

  src = gitAiSrc;
  cargoLock.lockFile = "${src}/Cargo.lock";

  CARGO_NET_OFFLINE = "true";
  OPENSSL_NO_VENDOR = "1";
  doCheck = false;

  postPatch = ''
    substituteInPlace src/metrics/model_pricing.rs \
      --replace-fail \
        'cfg!(test) || std::env::var_os("GIT_AI_TEST_DB_PATH").is_some()' \
        'true'
  '';

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    sqlite
    openssl
  ];

  postInstall = ''
    install -Dm644 agent-support/pi/git-ai.ts "$out/share/git-ai/oh-my-pi.ts"
    substituteInPlace "$out/share/git-ai/oh-my-pi.ts" \
      --replace-fail "@mariozechner/pi-coding-agent" "@oh-my-pi/pi-coding-agent" \
      --replace-fail "__GIT_AI_BINARY_PATH__" "$out/bin/git-ai" \
      --replace-fail "'.pi', 'agent', 'git-ai.override.json'" "'.omp', 'agent', 'git-ai.override.json'"
  '';

  meta = {
    description = "Git extension for tracking AI-generated code";
    homepage = "https://usegitai.com";
    license = lib.licenses.asl20;
    mainProgram = "git-ai";
  };
}
