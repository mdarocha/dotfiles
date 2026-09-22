vim.o.background = "dark"
require("solarized-osaka").setup({
  transparent = false,
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
})
vim.cmd.colorscheme("solarized-osaka")
