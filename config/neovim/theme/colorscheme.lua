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
    -- colors.border only feeds a disabled NvimTree/statusline option; borders below are set explicitly instead.
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

    -- osaka's SnacksPickerBorder has fg == bg_float, hiding every picker border by default-link; set each pane's accent explicitly.
    hl.FloatBorder = { fg = colors.base01, bg = colors.bg_float }
    hl.FloatTitle = { fg = colors.blue, bg = colors.bg_float, bold = true }
    hl.SnacksPickerBorder = { fg = colors.base01, bg = colors.bg_float }
    hl.SnacksPickerTitle = { fg = colors.orange, bg = colors.bg_float, bold = true }
    hl.SnacksPickerBoxBorder = { fg = colors.base01, bg = colors.bg_float }
    hl.SnacksPickerBoxTitle = { fg = colors.orange, bg = colors.bg_float, bold = true }
    hl.SnacksPickerInputBorder = { fg = colors.blue, bg = colors.bg_float }
    hl.SnacksPickerInputTitle = { fg = colors.blue, bg = colors.bg_float, bold = true }
    hl.SnacksPickerListBorder = { fg = colors.base01, bg = colors.bg_float }
    hl.SnacksPickerListTitle = { fg = colors.orange, bg = colors.bg_float, bold = true }
    hl.SnacksPickerPreviewBorder = { fg = colors.cyan, bg = colors.bg_float }
    hl.SnacksPickerPreviewTitle = { fg = colors.cyan, bg = colors.bg_float, bold = true }
    -- Preview's cursor line reuses the same "focused" tint as the list (see `selected` above).
    hl.SnacksPickerPreviewCursorLine = { bg = selected }
    hl.SnacksPickerPrompt = { fg = colors.cyan, bold = true }
    hl.SnacksPickerMatch = { fg = colors.orange, bold = true }
    hl.SnacksPickerSearch = { fg = colors.base03, bg = colors.yellow, bold = true }
    hl.SnacksPickerFile = { fg = colors.base1 }
    hl.SnacksPickerDir = { fg = colors.base01 }
    hl.SnacksPickerRow = { fg = colors.green }
    hl.SnacksPickerCol = { fg = colors.base00 }
    hl.SnacksPickerTotals = { fg = colors.base00 }
    hl.SnacksPickerDimmed = { fg = colors.base01 }
    hl.SnacksPickerSpecial = { fg = colors.violet }

    -- The "compact" notifier style draws a border; color each severity from the existing Diagnostic* palette.
    hl.SnacksNotifierInfo = { fg = colors.base0, bg = colors.bg_float }
    hl.SnacksNotifierWarn = { fg = colors.base0, bg = colors.bg_float }
    hl.SnacksNotifierError = { fg = colors.base0, bg = colors.bg_float }
    hl.SnacksNotifierDebug = { fg = colors.base00, bg = colors.bg_float }
    hl.SnacksNotifierTrace = { fg = colors.base00, bg = colors.bg_float }
    hl.SnacksNotifierBorderInfo = { fg = colors.blue, bg = colors.bg_float }
    hl.SnacksNotifierBorderWarn = { fg = colors.yellow, bg = colors.bg_float }
    hl.SnacksNotifierBorderError = { fg = colors.red, bg = colors.bg_float }
    hl.SnacksNotifierTitleInfo = { fg = colors.blue, bg = colors.bg_float, bold = true }
    hl.SnacksNotifierTitleWarn = { fg = colors.yellow, bg = colors.bg_float, bold = true }
    hl.SnacksNotifierTitleError = { fg = colors.red, bg = colors.bg_float, bold = true }
    hl.SnacksNotifierIconInfo = { fg = colors.blue, bg = colors.bg_float }
    hl.SnacksNotifierIconWarn = { fg = colors.yellow, bg = colors.bg_float }
    hl.SnacksNotifierIconError = { fg = colors.red, bg = colors.bg_float }
    local panel = colors.base02
    local active = colors.bg
    local accent = colors.blue -- shared sp/underline color so the selected-tab indicator has no gaps

    hl.BufferLineFill = { fg = colors.base01, bg = panel }
    hl.BufferLineTruncMarker = { fg = colors.base01, bg = panel }
    hl.BufferLineGroupSeparator = { fg = colors.base01, bg = panel }
    hl.BufferLineGroupLabel = { fg = panel, bg = colors.base01 }
    hl.BufferLineTab = { fg = colors.base0, bg = panel }
    hl.BufferLineTabSelected = { fg = colors.base1, bg = active, bold = true, sp = accent, underline = true }
    hl.BufferLineTabClose = { fg = colors.base0, bg = panel }

    hl.BufferLineBackground = { fg = colors.base0, bg = panel }
    hl.BufferLineBuffer = { fg = colors.base0, bg = panel }
    hl.BufferLineBufferVisible = { fg = colors.base1, bg = panel }
    hl.BufferLineBufferSelected = { fg = colors.base1, bg = active, bold = true, sp = accent, underline = true }

    hl.BufferLineCloseButton = { fg = colors.base0, bg = panel }
    hl.BufferLineCloseButtonVisible = { fg = colors.base1, bg = panel }
    hl.BufferLineCloseButtonSelected = { fg = colors.base1, bg = active, sp = accent, underline = true }

    -- dormant: options.numbers stays "none", defined anyway for completeness
    hl.BufferLineNumbers = { fg = colors.base0, bg = panel }
    hl.BufferLineNumbersVisible = { fg = colors.base1, bg = panel }
    hl.BufferLineNumbersSelected = { fg = colors.base1, bg = active, bold = true, sp = accent, underline = true }

    -- fallback for a severity with no diagnostic color of its own
    hl.BufferLineDiagnostic = { fg = colors.base0, bg = panel }
    hl.BufferLineDiagnosticVisible = { fg = colors.base1, bg = panel }
    hl.BufferLineDiagnosticSelected = { fg = colors.base1, bg = active, bold = true, sp = accent, underline = true }

    -- colored on every state, not just selected, so a broken buffer stands out while inactive
    local severities = {
      { name = "Error", fg = colors.red },
      { name = "Warning", fg = colors.yellow },
      { name = "Info", fg = colors.blue },
      { name = "Hint", fg = colors.green },
    }
    for _, sev in ipairs(severities) do
      hl["BufferLine" .. sev.name] = { fg = sev.fg, bg = panel }
      hl["BufferLine" .. sev.name .. "Visible"] = { fg = sev.fg, bg = panel }
      hl["BufferLine" .. sev.name .. "Selected"] =
        { fg = sev.fg, bg = active, bold = true, sp = accent, underline = true }
      hl["BufferLine" .. sev.name .. "Diagnostic"] = { fg = sev.fg, bg = panel }
      hl["BufferLine" .. sev.name .. "DiagnosticVisible"] = { fg = sev.fg, bg = panel }
      hl["BufferLine" .. sev.name .. "DiagnosticSelected"] =
        { fg = sev.fg, bg = active, bold = true, sp = accent, underline = true }
    end

    hl.BufferLineModified = { fg = colors.orange, bg = panel }
    hl.BufferLineModifiedVisible = { fg = colors.orange, bg = panel }
    hl.BufferLineModifiedSelected = { fg = colors.orange, bg = active, sp = accent, underline = true }
    hl.BufferLineDuplicate = { fg = colors.base01, italic = true, bg = panel }
    hl.BufferLineDuplicateVisible = { fg = colors.base01, italic = true, bg = panel }
    hl.BufferLineDuplicateSelected = { fg = colors.base01, italic = true, bg = active, sp = accent, underline = true }

    hl.BufferLineSeparator = { fg = colors.base01, bg = panel }
    hl.BufferLineSeparatorVisible = { fg = colors.base01, bg = panel }
    hl.BufferLineSeparatorSelected = { fg = panel, bg = active, sp = accent, underline = true }
    hl.BufferLineTabSeparator = { fg = colors.base01, bg = panel }
    hl.BufferLineTabSeparatorSelected = { fg = panel, bg = active, sp = accent, underline = true }

    -- fg=bg on purpose: hidden except for the underline drawn on the selected tab
    hl.BufferLineIndicatorSelected = { fg = accent, bg = active, sp = accent, underline = true }
    hl.BufferLineIndicatorVisible = { fg = panel, bg = panel }

    hl.BufferLinePick = { fg = colors.red, bold = true, bg = panel }
    hl.BufferLinePickVisible = { fg = colors.red, bold = true, bg = panel }
    hl.BufferLinePickSelected = { fg = colors.magenta, bold = true, bg = active, sp = accent, underline = true }

    -- mirrors the NvimTree sidebar bg it sits above
    hl.BufferLineOffsetSeparator = { fg = colors.base1, bg = colors.bg_sidebar }
  end,
})
vim.cmd.colorscheme("solarized-osaka")
