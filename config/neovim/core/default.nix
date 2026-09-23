# Base editor: aliases, leader keys, Python provider, clipboard, and Vim options (options.lua).
{ pkgs, pythonEnv, ... }:
{
  # vim/$EDITOR resolve to this nvim.
  vimAlias = true;
  defaultEditor = true;

  # Ruby provider is unused and its healthcheck needs network access; disable it.
  withRuby = false;

  nixpkgs.useGlobalPackages = true;

  globals = {
    mapleader = "\\";
    maplocalleader = ",";

    # Overrides nixvim's provider env so Molten and debugpy share one interpreter.
    python3_host_prog = "${pythonEnv}/bin/python3";
  };

  extraPackagesAfter = with pkgs; [
    # Clipboard provider for the unnamedplus register on Wayland.
    wl-clipboard

    # vim.ui.open's fallback opener outside WSL.
    xdg-utils

    # python3 provider, Molten's kernel, and the debugpy adapter.
    pythonEnv
  ];

  extraConfigLua = builtins.readFile ./options.lua;
}
