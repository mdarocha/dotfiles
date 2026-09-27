# Syntax: nvim-treesitter highlighting and indentation with grammars built by Nix.
{ pkgs, config, ... }:
{
  plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = true;
      indent.enable = true;
    };
    # Grammars are built by Nix, so Treesitter never downloads them at startup.
    grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
      bash
      c_sharp
      css
      html
      javascript
      json
      latex
      lua
      markdown
      markdown_inline
      nix
      python
      regex
      rust
      scss
      svelte
      tsx
      typescript
      typst
      vim
      vimdoc
      vue
      xml
      yaml
      zig
    ];
    languageRegister.json = "jsonc";
  };

  # Extra Nix injections (nixvim Lua, Home Manager shell snippets) on top of nvim-treesitter's.
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "nix-injections";
      src = ./runtime;
    })
  ];

  # nvim-treesitter's own :TSInstall path, unused here but silences its healthcheck.
  extraPackagesAfter = with pkgs; [
    tree-sitter
    gnutar
  ];
}
