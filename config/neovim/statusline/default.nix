# Statusline: lualine with Git diff, diagnostics, the attached LSP server count,
# and the active Python environment.
{ pkgs, ... }:
let
  # Upstream hasn't fixed this deprecation; patch the plugin source at build time.
  patchedLualine = pkgs.vimPlugins.lualine-nvim.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Table-form vim.validate{} is deprecated: https://github.com/nvim-lualine/lualine.nvim/issues/1399
      substituteInPlace lua/lualine/utils/fn_store.lua \
        --replace-fail \
          $'  vim.validate {\n    id = { id, \'n\' },\n    fn = { fn, \'f\' },\n  }' \
          $'  vim.validate("id", id, "number")\n  vim.validate("fn", fn, "function")' \
        --replace-fail \
          "vim.validate { id = { id, 'n' } }" \
          'vim.validate("id", id, "number")'
    '';
  });
in
{
  # Utility windows do not get a second statusline for the edited file.
  plugins.lualine = {
    enable = true;
    package = patchedLualine;
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

  # Recompute the LSP server count after a client attaches or detaches.
  extraConfigLua = ''
    vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
      callback = function()
        vim.schedule(function()
          require("lualine").refresh({ place = { "statusline" } })
        end)
      end,
    })
  '';
}
