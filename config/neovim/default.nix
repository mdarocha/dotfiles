{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mdarocha.neovim;

  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pynvim
      jupyter-client
      ipykernel
      debugpy
    ]
  );
  jupytextCli = pkgs.python3.withPackages (ps: [ ps.jupytext ]);

  toolPaths = {
    omp = "${config.mdarocha.llm-agents.oh-my-pi.package}/bin/omp";
  };

  bottomTerminal = ''
    function()
      Snacks.terminal(nil, { win = { position = "bottom" } })
    end
  '';

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
      (import ./modules/interface.nix)
      (import ./modules/workflow.nix {
        inherit pkgs pythonEnv bottomTerminal;
      })
    ];
  };
}
