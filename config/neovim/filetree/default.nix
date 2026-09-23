# File explorer: nvim-tree sidebar on the left with Git status and per-file diagnostics.
{ ... }:
{
  # nvim-tree takes over netrw.
  globals = {
    loaded_netrw = 1;
    loaded_netrwPlugin = 1;
  };

  # Tree diagnostics sit beside files rather than repeating up each parent.
  plugins.nvim-tree = {
    enable = true;
    settings = {
      sync_root_with_cwd = true;
      # layout.lua opens directories in the sidebar instead of the current window.
      hijack_directories.enable = false;
      update_focused_file.enable = true;
      diagnostics = {
        enable = true;
        show_on_dirs = false;
        show_on_open_dirs = false;
        icons = {
          hint = "󰌶";
          info = "󰋽";
          warning = "󰀪";
          error = "󰅖";
        };
      };
      git = {
        enable = true;
        show_on_dirs = true;
      };
      view = {
        side = "left";
        width = 36;
        signcolumn = "no";
        preserve_window_proportions = true;
      };
      renderer = {
        group_empty = true;
        indent_markers.enable = true;
        highlight_git = "name";
        highlight_diagnostics = "icon";
        icons = {
          diagnostics_placement = "after";
          show = {
            file = true;
            folder = true;
            folder_arrow = true;
            git = false;
          };
          glyphs = {
            default = "󰈔";
            symlink = "󰌷";
            folder = {
              arrow_closed = "󰅂";
              arrow_open = "󰅀";
              default = "󰉋";
              open = "󰝰";
              empty = "󰉖";
              empty_open = "󰷏";
              symlink = "󰉋";
              symlink_open = "󰝰";
            };
          };
        };
      };
      filters = {
        dotfiles = false;
        git_ignored = true;
      };
      actions.open_file.quit_on_open = false;
      on_attach.__raw = ''
        function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          local function opts(desc)
            return { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: " .. desc }
          end
          vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
          vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
          vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
        end
      '';
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action.__raw = "function() require('nvim-tree.api').tree.focus() end";
      options.desc = "Focus file explorer";
    }
    {
      mode = "n";
      key = "<A-l>";
      action.__raw = "function() require('nvim-tree.api').tree.toggle() end";
      options.desc = "Toggle file explorer";
    }
  ];

  extraConfigLua = builtins.readFile ./layout.lua;
}
