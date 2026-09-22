{
  pkgs,
  lib,
  pythonEnv,
  jupytextCli,
  toolPaths,
  luaModules,
}:
{
  enable = true;

  # vim/$EDITOR resolve to this nvim.
  vimAlias = true;
  defaultEditor = true;

  nixpkgs.useGlobalPackages = true;

  globals = {
    mapleader = "\\";
    maplocalleader = ",";
  };

  # Project direnv tools take precedence; these remain standalone fallbacks.
  extraPackagesAfter = with pkgs; [
    # File and content search for Snacks pickers and venv-selector.
    ripgrep
    fd

    # Converts images for snacks.image display.
    imagemagick

    # PATH-resolved language servers: roslyn.nvim starts roslyn-ls; vtsls
    # and Copilot run on node.
    roslyn-ls
    nodejs

    # Toolchain rust-analyzer shells out to.
    cargo
    rustc
    rustfmt

    # MSBuild for roslyn-ls; dotnet test for neotest-dotnet.
    dotnet-sdk

    # nvim-dap adapters; lldb provides lldb-dap for Rust.
    netcoredbg
    vscode-js-debug
    lldb

    # python3 provider, Molten's kernel, and the debugpy adapter.
    pythonEnv

    # jupytext.nvim's .ipynb conversion CLI.
    jupytextCli
  ];

  extraPlugins = with pkgs.vimPlugins; [
    solarized-osaka-nvim
    roslyn-nvim
    jupytext-nvim
  ];

  extraConfigLua = ''
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.g.python3_host_prog = "${pythonEnv}/bin/python3"

    vim.g.mdarocha_tools = {
      omp = "${toolPaths.omp}",
    }
  ''
  + lib.concatMapStringsSep "\n" builtins.readFile luaModules;
}
