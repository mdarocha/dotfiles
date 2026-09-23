# Home Manager entry point for the Neovim workbench. nixvim builds Neovim from
# the feature modules below; each subdirectory is a nixvim module that owns one
# feature's plugins, packages, keymaps, and Lua. Modules add tools through
# extraPackagesAfter so project direnv tools take precedence on PATH.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mdarocha.neovim;

  # One Python runtime serves Neovim's provider (core), Molten's kernel
  # (notebook), and the debugpy adapter (debug).
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pynvim
      jupyter-client
      ipykernel
      debugpy

      # Molten's optional output renderers (SVG, LaTeX, plots, clipboard).
      cairosvg
      pnglatex
      plotly
      kaleido
      pyperclip
      pillow
    ]
  );
in
{
  options.mdarocha.neovim = {
    enable = mkEnableOption "neovim editor configuration";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;

      # Import order is the order of each module's Lua in init.lua.
      imports = [
        ./core
        ./theme
        ./snacks
        ./filetree
        ./outline
        ./tabs
        ./statusline
        ./hints
        ./session
        ./treesitter
        ./completion
        ./lsp
        ./copilot
        ./git
        ./notebook
        ./debug
        ./test
      ];

      _module.args = { inherit pythonEnv; };
    };
  };
}
