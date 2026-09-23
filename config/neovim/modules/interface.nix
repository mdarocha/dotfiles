{ pkgs }:
{
  plugins = {
    web-devicons.enable = true;

    # Snacks keeps temporary UI out of the dedicated file and symbol panes.
    snacks = {
      enable = true;
      settings = {
        bigfile.enabled = true;
        notifier = {
          enabled = true;
          style = "compact";
          timeout = 2500;
          padding = true;
          filter.__raw = ''
            function(notif)
              if notif.title == "Snacks" then
                notif.title = nil
              end
              return true
            end
          '';
        };
        quickfile.enabled = true;
        statuscolumn.enabled = true;
        words.enabled = true;
        explorer.enabled = false;
        indent = {
          enabled = true;
          scope.enabled = false;
          chunk.enabled = false;
        };
        picker = {
          enabled = true;
          ui_select = true;
          # ffi.load("sqlite3") has no RPATH; point it at Nix's build.
          db.sqlite3_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
        };
        terminal = {
          enabled = true;
          win = {
            position = "bottom";
            height = 0.32;
            wo.statusline = "   Terminal";
            wo.winbar = "";
          };
        };
        image.enabled = true;
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

    # Tree diagnostics sit beside files rather than repeating up each parent.
    nvim-tree = {
      enable = true;
      settings = {
        sync_root_with_cwd = true;
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

    # Follow the active editor buffer while keeping the outline at the edge.
    aerial = {
      enable = true;
      settings = {
        backends = [
          "treesitter"
          "lsp"
          "markdown"
          "man"
        ];
        attach_mode = "global";
        filter_kind = false;
        layout = {
          placement = "edge";
          default_direction = "prefer_right";
          min_width = 24;
          max_width = [
            40
            0.2
          ];
          resize_to_content = true;
        };
        nerd_font = true;
        show_guides = true;
        highlight_mode = "split_width";
      };
    };

    # Prefix hints float in the corner instead of replacing the command line.
    mini = {
      enable = true;
      modules.clue = {
        triggers = [
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>";
          }
        ];
        clues = [
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>s";
            desc = "+search";
          }
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>g";
            desc = "+git";
          }
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>h";
            desc = "+git hunk";
          }
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>d";
            desc = "+debug";
          }
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>t";
            desc = "+test";
          }
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>o";
            desc = "+oh-my-pi";
          }
          {
            mode = [
              "n"
              "x"
            ];
            keys = "<Leader>b";
            desc = "+buffer";
          }
        ];
        window = {
          delay = 300;
          scroll_down = "<C-d>";
          scroll_up = "<C-u>";
          config = {
            anchor = "SE";
            row = "auto";
            col = "auto";
            width = "auto";
            border = "rounded";
          };
        };
      };
    };

    # Utility windows do not get a second statusline for the edited file.
    lualine = {
      enable = true;
      settings = {
        options = {
          theme = "solarized_dark";
          component_separators = {
            left = "│";
            right = "│";
          };
          section_separators = {
            left = "";
            right = "";
          };
          disabled_filetypes.statusline = [
            "NvimTree"
            "aerial"
            "snacks_terminal"
            "snacks_picker_input"
            "snacks_picker_list"
            "snacks_picker_preview"
            "snacks_notif"
            "snacks_notif_history"
            "dap-repl"
            "dapui_scopes"
            "dapui_breakpoints"
            "dapui_stacks"
            "dapui_watches"
            "dapui_console"
            "dapui_hover"
            "neotest-summary"
            "neotest-output"
            "neotest-output-panel"
            "prompt"
            "help"
          ];
        };
        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [
            "branch"
          ];
          lualine_c = [ "filename" ];
          lualine_x = [
            {
              __unkeyed-1 = "diff";
              diff_color = {
                added.fg.__raw = "require('solarized-osaka.colors').setup().green300";
                modified.fg.__raw = "require('solarized-osaka.colors').setup().yellow300";
                removed.fg.__raw = "require('solarized-osaka.colors').setup().red300";
              };
            }
            {
              __unkeyed-1 = "diagnostics";
              sources = [ "nvim_diagnostic" ];
              sections = [
                "error"
                "warn"
              ];
              diagnostics_color = {
                error.fg.__raw = "require('solarized-osaka.colors').setup().red300";
                warn.fg.__raw = "require('solarized-osaka.colors').setup().yellow300";
              };
            }
            {
              __unkeyed-1.__raw = ''
                function()
                  return #vim.lsp.get_clients({ bufnr = 0 })
                end
              '';
              icon = "󰒋";
              on_click.__raw = ''
                function()
                  local clients = vim.lsp.get_clients({ bufnr = 0 })
                  local names = {}
                  for _, client in ipairs(clients) do
                    names[#names + 1] = client.name
                  end
                  table.sort(names)
                  local message = #names == 0 and "No servers attached" or table.concat(names, "\n")
                  require("fidget").notify(message, vim.log.levels.INFO, {
                    group = "LSP",
                    key = "attached",
                    ttl = 6,
                  })
                end
              '';
            }
            {
              __unkeyed-1.__raw = ''
                function()
                  local selected = nil
                  local ok, venv = pcall(require, "venv-selector")
                  if ok and venv.venv then
                    selected = venv.venv()
                  end
                  selected = selected or vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
                  if not selected then
                    return ""
                  end
                  local name = vim.fn.fnamemodify(selected, ":t")
                  if name == ".venv" or name == "venv" then
                    name = vim.fn.fnamemodify(selected, ":h:t")
                  elseif selected:match("^/nix/store/") then
                    local version = name:match("%-python%d*%-([%d%.]+)%-env$")
                    if version then
                      name = "python " .. version
                    end
                  end
                  return #name > 22 and "…" .. name:sub(-21) or name
                end
              '';
              icon = "";
              color = "DiagnosticInfo";
              cond.__raw = ''
                function()
                  local ok, venv = pcall(require, "venv-selector")
                  local selected = ok and venv.venv and venv.venv() or nil
                  return selected ~= nil or vim.env.VIRTUAL_ENV ~= nil or vim.env.CONDA_PREFIX ~= nil
                end
              '';
            }
            "encoding"
            "fileformat"
            "filetype"
          ];
          lualine_y = [ "progress" ];
          lualine_z = [ "location" ];
        };
      };
    };

    # The sidebar reserves tabline space but never becomes a file tab.
    bufferline = {
      enable = true;
      settings.options = {
        mode = "buffers";
        diagnostics = "nvim_lsp";
        separator_style = "thin";
        indicator.style = "underline";
        tab_size = 18;
        truncate_names = false;
        # bufferline only skips truncation once a name is at least max_name_length long, so keep it low
        max_name_length = 1;
        offsets = [
          {
            filetype = "NvimTree";
            text = " 󰙅 Files";
            text_align = "left";
            separator = true;
            highlight = "BufferLineOffsetSeparator";
          }
        ];
        custom_filter.__raw = ''
          function(bufnr)
            local buffer = vim.bo[bufnr]
            if buffer.buftype ~= "" or buffer.filetype == "NvimTree" or buffer.filetype == "aerial" then
              return false
            end
            if buffer.filetype == "" then
              local name = vim.api.nvim_buf_get_name(bufnr)
              -- Older sessions can restore NvimTree_1 as a nonexistent regular file.
              if vim.fn.fnamemodify(name, ":t"):match("^NvimTree_%d+$") and vim.fn.filereadable(name) == 0 then
                return false
              end
            end
            return true
          end
        '';
        show_buffer_icons = true;
        show_buffer_close_icons = true;
        show_close_icon = false;
        buffer_close_icon = "󰅖";
        modified_icon = "●";
        left_mouse_command = "buffer %d";
        close_command = "bdelete %d";
        right_mouse_command = "bdelete %d";
        middle_mouse_command = "bdelete %d";
      };
      # Devicon *Selected/Visible highlights (BufferLineDevIcon<Ft>Selected, etc.) are generated
      # by bufferline from this table, not from the `hl.BufferLine*` groups in ui.lua, so the
      # panel/bg/blue-underline accent has to be repeated here to keep file icons in sync.
      settings.highlights.__raw = ''
        function(defaults)
          if require("solarized-osaka.config").is_light() then
            return {}
          end
          return {
            background = { bg = "#073642" },
            buffer_visible = { bg = "#073642" },
            buffer_selected = { bg = "#002b36", sp = "#268bd3", underline = true },
          }
        end
      '';
    };

    # Skip scratch panes on save so restored sessions contain real files.
    auto-session = {
      enable = true;
      settings = {
        auto_restore_last_session = true;
        bypass_save_filetypes = [
          "NvimTree"
          "aerial"
          "snacks_dashboard"
          "snacks_terminal"
          "prompt"
          "help"
        ];
        close_filetypes_on_save = [
          "checkhealth"
          "NvimTree"
          "aerial"
          "snacks_terminal"
          "snacks_picker_input"
          "snacks_picker_list"
          "snacks_picker_preview"
        ];
      };
    };

  };
}
