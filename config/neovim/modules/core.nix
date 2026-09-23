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

  # Ruby provider is unused and its healthcheck needs network access; disable it.
  withRuby = false;

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

    # Clipboard provider for the unnamedplus register on Wayland.
    wl-clipboard

    # Converts images for snacks.image display.
    imagemagick

    # PDF, LaTeX, and Mermaid rendering for snacks.image.
    ghostscript
    tectonic
    mermaid-cli

    # System trash for Snacks.explorer deletions.
    trash-cli

    # Snacks.lazygit backend; the lazygit.nvim module itself stays disabled.
    lazygit

    # vim.ui.open's fallback opener outside WSL.
    xdg-utils

    # nvim-treesitter's own :TSInstall path, unused here but silences its healthcheck.
    tree-sitter
    gnutar

    # PATH-resolved language servers: roslyn.nvim starts roslyn-ls; vtsls
    # and Copilot run on node.
    roslyn-ls
    nodejs

    # Toolchain rust-analyzer shells out to.
    cargo
    rustc
    rustfmt

    # MSBuild for roslyn-ls; dotnet test for neotest-dotnet.
    dotnet-sdk_10

    # nvim-dap adapters; lldb provides lldb-dap for Rust.
    netcoredbg
    vscode-js-debug
    lldb

    # python3 provider, Molten's kernel, and the debugpy adapter.
    pythonEnv

    # jupytext.nvim's .ipynb conversion CLI.
    jupytextCli
  ];

  # Nix supplies these plugins directly; their setup lives in the Lua files below.
  extraPlugins = with pkgs.vimPlugins; [
    solarized-osaka-nvim
    roslyn-nvim
  ];

  # This prelude runs before the inlined Lua files; nvim-tree takes over netrw.
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
