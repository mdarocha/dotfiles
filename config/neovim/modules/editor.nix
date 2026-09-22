{ config }:
{
  plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
      # Grammars are built by Nix, so Treesitter never downloads them at startup.
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        bash
        c_sharp
        css
        html
        javascript
        json
        lua
        markdown
        markdown_inline
        nix
        python
        rust
        tsx
        typescript
        vim
        vimdoc
        xml
        yaml
        zig
      ];
      languageRegister.json = "jsonc";
    };

    # Lazydev adds Neovim and installed plugin types only when editing Lua.
    lazydev.enable = true;

    blink-cmp = {
      enable = true;
      settings = {
        # Arrow keys keep their usual behavior when completion is closed.
        keymap = {
          preset = "default";
          "<Up>" = [
            "select_prev"
            "fallback"
          ];
          "<Down>" = [
            "select_next"
            "fallback"
          ];
        };
        cmdline.keymap = {
          preset = "cmdline";
          "<Up>" = [
            "select_prev"
            "fallback"
          ];
          "<Down>" = [
            "select_next"
            "fallback"
          ];
        };
        completion = {
          menu.border = "rounded";
          documentation.window.border = "rounded";
        };
        signature.window.border = "rounded";
      };
    };

    schemastore.enable = true;

    # nixvim registers the servers with Neovim's built-in LSP client.
    lsp = {
      enable = true;
      servers = {
        nil_ls = {
          enable = true;
          settings.nix.flake.autoArchive = false;
        };
        lua_ls = {
          enable = true;
          # Config Lua uses these globals without require calls.
          settings.Lua = {
            runtime.version = "LuaJIT";
            diagnostics.globals = [
              "vim"
              "Snacks"
            ];
            workspace.checkThirdParty = false;
          };
        };
        pyright.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
          installRustfmt = false;
        };
        vtsls = {
          enable = true;
          settings = {
            javascript.updateImportsOnFileMove.enabled = "always";
            typescript.updateImportsOnFileMove.enabled = "always";
          };
        };
        html.enable = true;
        cssls.enable = true;
        jsonls.enable = true;
        yamlls.enable = true;
        lemminx.enable = true;
        zls.enable = true;
      };
    };
  };

}
