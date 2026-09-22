-- Osaka starts darker than Ghostty's Solarized theme.
vim.o.background = "dark"
require("solarized-osaka").setup({
  transparent = false,
  -- Keep the light variant upstream; only dark backgrounds match Ghostty.
  on_colors = function(colors)
    if require("solarized-osaka.config").is_light() then
      return
    end

    colors.bg = "#002b36"
    colors.base04 = colors.bg
    colors.base03 = colors.bg
    colors.base02 = "#073642"
    colors.bg_highlight = colors.base02
    colors.bg_popup = colors.base02
    colors.bg_sidebar = colors.base02
    colors.bg_float = colors.base02
    colors.bg_statusline = colors.base02
    colors.border = colors.base02
  end,
  on_highlights = function(hl, colors)
    ---@cast hl table<string, table>
    -- Number gutters stay neutral instead of Osaka's orange and yellow.
    hl.LineNr = { fg = colors.base00, bg = colors.bg }
    hl.CursorLineNr = { fg = colors.base0, bg = colors.bg_highlight, bold = true }
    hl.NvimTreeFolderArrowClosed = { fg = colors.base0, bg = colors.bg_sidebar }
    hl.NvimTreeFolderArrowOpen = { fg = colors.cyan, bg = colors.bg_sidebar }
    -- Picker results use CursorLine while the search input has focus.
    local selected = require("solarized-osaka.config").is_light() and "#d8e2df" or "#124653"
    hl.CursorLine = { bg = selected }
    hl.SnacksPickerListCursorLine = { fg = colors.base1, bg = selected, bold = true }
    local panel = colors.base02
    -- BufferLine's default shading makes inactive tabs too dark on Osaka.
    hl.BufferLineFill = { bg = colors.bg }
    hl.BufferLineBackground = { fg = colors.base0, bg = panel }
    hl.BufferLineBufferVisible = { fg = colors.base0, bg = panel }
    hl.BufferLineBufferSelected = { fg = colors.base1, bg = colors.bg, bold = true, sp = colors.blue, underline = true }
    hl.BufferLineIndicatorSelected = { fg = colors.blue, bg = colors.bg }
    hl.BufferLineCloseButton = { fg = colors.base0, bg = panel }
    hl.BufferLineCloseButtonVisible = { fg = colors.base0, bg = panel }
    hl.BufferLineCloseButtonSelected = { fg = colors.base1, bg = colors.bg, sp = colors.blue, underline = true }
    hl.BufferLineSeparator = { fg = colors.bg, bg = panel }
    hl.BufferLineSeparatorVisible = { fg = colors.bg, bg = panel }
    hl.BufferLineSeparatorSelected = { fg = panel, bg = colors.bg }
    hl.BufferLineModified = { fg = colors.orange, bg = panel }
    hl.BufferLineModifiedSelected = { fg = colors.orange, bg = colors.bg }
    hl.BufferLineOffsetSeparator = { fg = colors.base1, bg = colors.bg_sidebar }
  end,
})
vim.cmd.colorscheme("solarized-osaka")
