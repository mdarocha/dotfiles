# Buffer tabs: bufferline shows every open file buffer as a tab; gt/gT cycle them
# from any window (cycle.lua).
{ ... }:
{
  # The sidebar reserves tabline space but never becomes a file tab.
  plugins.bufferline = {
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

  keymaps = [
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<CR>";
      options.desc = "Close buffer";
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>BufferLinePick<CR>";
      options.desc = "Pick buffer";
    }
  ];

  extraConfigLua = builtins.readFile ./cycle.lua;
}
