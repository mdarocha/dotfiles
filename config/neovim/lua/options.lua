vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.textwidth = 120
vim.opt.colorcolumn = { "80", "120" }
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

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
