{ pkgs }:

let
  # This single list drives both the Nix environment and the agent
  # instructions, so they never drift apart.
  packageNames = [
    "ipykernel"
    "jupyter_kernel_gateway"

    # PDF skill
    "pypdf"
    "pdfplumber"
    "reportlab"
    "pillow"
    "pandas"
    "pytesseract"
    "pdf2image"
    "pypdfium2"

    # DOCX/PPTX/XLSX skills
    "openpyxl"
    "defusedxml"
    "lxml"
    "python-pptx"

    # Data processing and analysis
    "numpy"
    "matplotlib"
    "pyyaml"
    "toml"

    # HTTP and web
    "requests"
    "beautifulsoup4"

    # General utilities
    "python-dateutil"
    "chardet"
    "jsonschema"
    "jinja2"
  ];
in
{
  inherit packageNames;

  # jupyter_kernel_gateway is added to pkgs.python3Packages by the repo's
  # nixpkgs overlay.
  env = pkgs.python3.withPackages (ps: map (name: ps.${name}) packageNames);
}
