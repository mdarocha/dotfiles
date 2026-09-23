# Colors and icons: Solarized Osaka matched to Ghostty's Solarized canvas, plus
# highlight overrides for pickers, notifications, the tree, and tabs (colorscheme.lua).
{ pkgs, ... }:
{
  # Nix supplies the plugin directly; colorscheme.lua calls its setup.
  extraPlugins = [ pkgs.vimPlugins.solarized-osaka-nvim ];

  plugins.web-devicons.enable = true;

  # Default border for native floats without one; see :h 'winborder'.
  opts.winborder = "rounded";

  extraConfigLua = builtins.readFile ./colorscheme.lua;
}
