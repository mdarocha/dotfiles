# Language servers and LSP keymaps, plus helpers: lazydev (Lua types), SchemaStore
# (JSON/YAML schemas), roslyn.nvim (C#), vtsls commands, venv-selector, fidget popups,
# and otter (servers for code embedded in Nix strings).
{ pkgs, lib, ... }:
let
  # Keeps embedded lines split by a Nix `${...}` intact (https://github.com/jmbuhr/otter.nvim/issues/285).
  patchedOtter = pkgs.vimPlugins.otter-nvim.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./otter-interpolation.patch ];
  });
in
{
  plugins = {
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
        bashls.enable = true;
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
        yamlls = {
          enable = true;
          # lspconfig's dotted defaults never occur; ftdetect only sets plain "yaml".
          filetypes = [ "yaml" ];
        };
        lemminx = {
          enable = true;
          # "xsl" is lspconfig's default but Neovim's ftdetect names .xsl files "xslt".
          filetypes = [
            "xml"
            "xsd"
            "xslt"
            "svg"
          ];
        };
        zls.enable = true;
      };
    };

    # Lazydev adds Neovim and installed plugin types only when editing Lua.
    lazydev.enable = true;

    # JSON and YAML schemas for jsonls and yamlls.
    schemastore.enable = true;

    # Pyright picks up the selected venv after a restart (lsp.lua).
    venv-selector.enable = true;

    # Bash, Lua, and Python inside Nix strings reach their servers via hidden buffers (embedded.lua).
    otter = {
      enable = true;
      package = patchedOtter;
      autoActivate = false;
      settings = {
        lsp.diagnostic_update_events = [
          "BufWritePost"
          "InsertLeave"
          "TextChanged"
        ];
        # One line each; embedded code starting on line 2 would overwrite the rest.
        buffers.preambles = {
          # `${...}` trips SC1090/SC2086/SC2154/SC2296; SC2093 since a file's snippets share one script.
          bash = [ "# shellcheck shell=bash disable=SC1090,SC2086,SC2093,SC2154,SC2296" ];
          # nixvim `__raw` values are bare expressions; closing `''` lines keep their indent.
          lua = [
            "---@diagnostic disable: miss-name, exp-in-action, unreachable-code, trailing-space"
          ];
        };
      };
    };

    # LSP messages share a small popup; chatty LuaLS progress is omitted.
    fidget = {
      enable = true;
      settings = {
        progress.ignore = [ "lua_ls" ];
        progress.display = {
          done_ttl = 1;
          render_limit = 3;
        };
        notification.window = {
          normal_hl = "NormalFloat";
          winblend = 0;
          border = "rounded";
          border_hl = "FloatBorder";
          max_width = 52;
          max_height = 8;
        };
      };
    };
  };

  # roslyn.nvim replaces lspconfig's C# support; roslyn.lua configures it.
  extraPlugins = [ pkgs.vimPlugins.roslyn-nvim ];

  extraPackagesAfter = with pkgs; [
    # PATH-resolved language servers: roslyn.nvim starts roslyn-ls; vtsls runs on node.
    roslyn-ls
    nodejs

    # MSBuild for roslyn-ls.
    dotnet-sdk_10

    # Toolchain rust-analyzer shells out to.
    cargo
    rustc
    rustfmt

    # bash-language-server lints with ShellCheck and formats with shfmt.
    shellcheck
    shfmt

    # Virtual environment search for venv-selector.
    fd
  ];

  keymaps = [
    {
      mode = "n";
      key = "gd";
      action.__raw = "function() Snacks.picker.lsp_definitions() end";
      options.desc = "Go to definition";
    }
    # Shares a prefix with Neovim's grn/gra/gri/grr, so it waits for 'timeoutlen'.
    {
      mode = "n";
      key = "gr";
      action.__raw = "function() Snacks.picker.lsp_references() end";
      options.desc = "References";
    }
    {
      mode = "n";
      key = "<C-]>";
      action.__raw = "function() Snacks.picker.lsp_implementations() end";
      options.desc = "Go to implementation";
    }
    {
      mode = "n";
      key = "<A-CR>";
      action.__raw = "vim.lsp.buf.code_action";
      options.desc = "Code actions";
    }
    {
      mode = "n";
      key = "\\r";
      action.__raw = "vim.lsp.buf.rename";
      options.desc = "Rename symbol";
    }
    # Override Neovim's quickfix-based LSP lookups.
    {
      mode = "n";
      key = "grr";
      action.__raw = "function() Snacks.picker.lsp_references() end";
      options.desc = "References";
    }
    {
      mode = "n";
      key = "gri";
      action.__raw = "function() Snacks.picker.lsp_implementations() end";
      options.desc = "Go to implementation";
    }
    {
      mode = "n";
      key = "grt";
      action.__raw = "function() Snacks.picker.lsp_type_definitions() end";
      options.desc = "Go to type definition";
    }
    {
      mode = "n";
      key = "gO";
      action.__raw = "function() Snacks.picker.lsp_symbols() end";
      options.desc = "Document symbols";
    }
  ];

  extraConfigLua = lib.concatMapStringsSep "\n" builtins.readFile [
    ./lsp.lua
    ./roslyn.lua
    ./vtsls.lua
    ./embedded.lua
  ];
}
