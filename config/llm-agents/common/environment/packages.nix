{
  pkgs,
  lib,
  chromium,
  pythonEnv,
}:

let
  list = with pkgs; [
    # Misc tools
    git
    git-lfs
    gh
    # devenv-managed repos exec `prek` from git hooks; absent from
    # PATH, `git commit` fails with "prek: not found".
    prek
    coreutils
    findutils
    gnused
    gnugrep
    gawk
    curl
    jq
    ripgrep
    fd
    which
    diffutils
    chromium
    wl-clipboard
    binutils
    file
    procps

    # PDF/office skills: CLI tools for document processing
    poppler-utils
    qpdf
    pandoc
    libreoffice-stable
    tesseract
    imagemagick
    ffmpeg

    # Python
    pythonEnv
    pyright

    # Node.js / JavaScript / TypeScript
    nodejs
    bun
    typescript-language-server

    # Rust
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # Nix
    nixd
  ];

  cleanName =
    raw:
    let
      withoutWrapper = lib.removeSuffix "-wrapper" raw;
      versionMatch = builtins.match "(.+)-[0-9].*" withoutWrapper;
    in
    if versionMatch != null then builtins.head versionMatch else withoutWrapper;

  getName =
    p:
    if p ? pname then
      cleanName p.pname
    else if p ? name then
      cleanName p.name
    else
      null;
in
{
  inherit list;
  names = builtins.filter (n: n != null) (map getName list);
}
