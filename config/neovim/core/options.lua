vim.opt.number = false
vim.opt.relativenumber = false
-- Lualine shows mode, so Neovim's own INSERT message would repeat it.
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
-- Mouse clicks reach tabs and panes; wheel steps stay at one row.
vim.opt.mouse = "a"
vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.textwidth = 120
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"
-- WSLg's wl-copy doesn't reliably reach the Windows clipboard; use `:h clipboard-wsl`.
if vim.fn.has("wsl") == 1 then
  local paste = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end

-- Reveal whitespace as Nerd Font octicons; Whitespace/NonText (theme) color them.
vim.opt.list = true
vim.opt.listchars = {
  tab = "\u{f432} ", -- arrow-right
  trail = "\u{f444}", -- dot-fill
  nbsp = "\u{f4c3}", -- dot
  extends = "\u{f460}", -- chevron-right
  precedes = "\u{f47d}", -- chevron-left
}

-- File buffers switch between absolute and relative numbers; panes keep their own gutters.
local function set_editor_numbers()
  if vim.bo.buftype ~= "" then
    return
  end

  local normal = vim.fn.mode(1):sub(1, 1) == "n"
  vim.wo.number = true
  vim.wo.relativenumber = not normal
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "ModeChanged" }, {
  callback = set_editor_numbers,
})
set_editor_numbers()

-- Two-space indent for markup and config languages.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc", "yaml", "xml", "nix", "lua" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- Neovim has no filetype rule for MSBuild project files.
vim.filetype.add({
  extension = {
    csproj = "xml",
    fsproj = "xml",
    props = "xml",
  },
})

-- Saves on focus change. Skips terminals, pickers, and unnamed or read-only
-- buffers.
local function autosave()
  if vim.bo.modified and vim.bo.buftype == "" and vim.bo.filetype ~= "" and vim.fn.expand("%") ~= "" and not vim.bo.readonly then
    vim.cmd("silent! write")
  end
end

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  callback = autosave,
})
