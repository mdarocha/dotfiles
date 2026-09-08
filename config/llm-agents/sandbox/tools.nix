{ pkgs }:
let
  pythonEvalPackageNames = [
    "ipykernel"
    "jupyter_kernel_gateway"
    "pypdf"
    "pdfplumber"
    "reportlab"
    "pillow"
    "pandas"
    "pytesseract"
    "pdf2image"
    "pypdfium2"
    "openpyxl"
    "defusedxml"
    "lxml"
    "python-pptx"
    "numpy"
    "matplotlib"
    "pyyaml"
    "toml"
    "requests"
    "beautifulsoup4"
    "python-dateutil"
    "chardet"
    "jsonschema"
    "jinja2"
  ];

  pythonEvalEnv = pkgs.python3.withPackages (ps: map (name: ps.${name}) pythonEvalPackageNames);

  # Use the store-provided Mesa stack so sandboxed Chromium can load compatible userspace drivers.
  mesaDriverEnv = ''
    export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
    export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
    export VK_ICD_FILENAMES="${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json"
    export GBM_BACKENDS_PATH="${pkgs.mesa}/lib/gbm"
  '';

  chromiumWrapper = pkgs.writeShellScriptBin "chromium" ''
    if [ -f /tmp/sandbox-ca-cert.pem ]; then
      NSS_DB="$HOME/.pki/nssdb"
      if [ ! -d "$NSS_DB" ]; then
        mkdir -p "$NSS_DB"
        ${pkgs.nss.tools}/bin/certutil -d "sql:$NSS_DB" -N --empty-password 2>/dev/null
      fi
      ${pkgs.nss.tools}/bin/certutil -d "sql:$NSS_DB" -A \
        -n "sandbox-proxy-ca" -t "C,," \
        -i /tmp/sandbox-ca-cert.pem 2>/dev/null || true
    fi
    ${mesaDriverEnv}
    exec ${pkgs.chromium}/bin/chromium --no-sandbox --disable-dev-shm-usage "$@"
  '';

  allowedPackages = with pkgs; [
    git git-lfs gh prek coreutils findutils gnused gnugrep gawk curl jq ripgrep fd which diffutils chromiumWrapper wl-clipboard binutils file procps
    poppler-utils qpdf pandoc libreoffice-stable tesseract imagemagick
    pythonEvalEnv pyright
    nodejs bun typescript-language-server
    cargo rustc rustfmt clippy rust-analyzer
    nixd
  ];
in
{
  inherit pythonEvalPackageNames pythonEvalEnv chromiumWrapper allowedPackages;
}
