{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mdarocha.neovim;

  # One Python runtime serves Neovim's provider, Molten, and the debug adapter.
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
  jupytextCli = pkgs.python3.withPackages (ps: [ ps.jupytext ]);

  toolPaths = {
    omp = "${config.mdarocha.llm-agents.oh-my-pi.package}/bin/omp";
  };

  # Terminal shortcuts share the same bottom split behavior.
  bottomTerminal = ''
    function()
      Snacks.terminal(nil, { win = { position = "bottom" } })
    end
  '';

  # These Lua files become one init script in this order.
  luaModules = [
    ./lua/options.lua
    ./lua/ui.lua
    ./lua/lsp.lua
    ./lua/workbench.lua
    ./lua/keymaps.lua
  ];
in
{
  options.mdarocha.neovim = {
    enable = mkEnableOption "neovim editor configuration";
  };

  config = mkIf cfg.enable {
    # Keep packaging, language support, UI, and workflow settings separate.
    programs.nixvim = lib.mkMerge [
      (import ./modules/core.nix {
        inherit
          pkgs
          lib
          pythonEnv
          jupytextCli
          toolPaths
          luaModules
          ;
      })
      (import ./modules/editor.nix { inherit config; })
      (import ./modules/interface.nix { inherit pkgs; })
      (import ./modules/workflow.nix {
        inherit pkgs pythonEnv bottomTerminal;
      })
      (import ./modules/patches.nix { inherit pkgs; })
    ];
  };
}
