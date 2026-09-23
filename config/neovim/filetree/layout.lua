-- Keeps nvim-tree a sidebar beside an editor window; the editor shows the
-- dashboard while no file is open.
local api = require("nvim-tree.api")

local sidebars = { NvimTree = true, aerial = true }

local function is_floating(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function is_sidebar(win)
  return sidebars[vim.bo[vim.api.nvim_win_get_buf(win)].filetype] == true
end

local function tiled_windows()
  return vim.tbl_filter(function(win)
    return not is_floating(win)
  end, vim.api.nvim_tabpage_list_wins(0))
end

local function is_directory(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.isdirectory(name) == 1
end

-- What Neovim shows when nothing is open: an unnamed, untouched, empty file buffer.
local function is_blank(buf)
  return vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) == ""
    and not vim.bo[buf].modified
    and vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

local function recent_file()
  local recent
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if not is_blank(info.bufnr) and not is_directory(info.bufnr) and (not recent or info.lastused > recent.lastused) then
      recent = info
    end
  end
  return recent and recent.bufnr
end

-- Drops the blank or directory buffer the dashboard covers so it doesn't linger as a tab.
local function show_dashboard(win)
  local covered = vim.api.nvim_win_get_buf(win)
  Snacks.dashboard.open({ win = win, buf = vim.api.nvim_create_buf(false, true) })

  local disposable = vim.bo[covered].buflisted and (is_blank(covered) or is_directory(covered))
  if disposable and #vim.fn.win_findbuf(covered) == 0 then
    vim.api.nvim_buf_delete(covered, { force = true })
  end
end

-- Sidebar widths before the pending window closes widened them.
local sidebar_widths = {}

local function keep_editor()
  local widths = sidebar_widths
  sidebar_widths = {}
  if vim.v.exiting ~= vim.NIL or vim.g.SessionLoad == 1 then
    return
  end

  -- Once only sidebars remain, reopen an editor beside them with the last file or the dashboard.
  local wins = tiled_windows()
  if #wins == 0 then
    return
  end
  for _, win in ipairs(wins) do
    if not is_sidebar(win) then
      return
    end
  end

  local file = recent_file()
  local buf = file or vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, { split = "right", win = wins[1] })
  for _, sidebar in ipairs(wins) do
    if widths[sidebar] then
      vim.api.nvim_win_set_width(sidebar, widths[sidebar])
    end
  end
  if not file then
    Snacks.dashboard.open({ win = win, buf = buf })
  end
end

local function fill_blank_editors()
  if vim.v.exiting ~= vim.NIL or vim.g.SessionLoad == 1 or recent_file() then
    return
  end

  for _, win in ipairs(tiled_windows()) do
    if not is_sidebar(win) and is_blank(vim.api.nvim_win_get_buf(win)) then
      show_dashboard(win)
      return
    end
  end
end

-- Puts a directory buffer's windows back on the previous file (or the dashboard) and returns the directory.
local function replace_directory(buf)
  local dir = vim.api.nvim_buf_get_name(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local alt = vim.api.nvim_win_call(win, function()
      return vim.fn.bufnr("#")
    end)
    if alt > 0 and alt ~= buf and vim.bo[alt].buflisted then
      vim.api.nvim_win_set_buf(win, alt)
    else
      show_dashboard(win)
    end
  end

  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  return dir
end

local function on_startup()
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  local restored = vim.v.this_session ~= ""
  local argc = vim.fn.argc(-1)
  local dir_arg = argc == 1 and vim.fn.isdirectory(vim.fn.argv(0, -1)) == 1
  local current = vim.api.nvim_get_current_buf()
  if not restored and (argc > 0 and not dir_arg or not is_blank(current) and not is_directory(current)) then
    return
  end

  -- A restored session already cd'd into its directory.
  if dir_arg and not restored then
    vim.cmd.cd(vim.fn.fnameescape(vim.fn.argv(0, -1)))
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_directory(buf) then
      replace_directory(buf)
    end
  end
  fill_blank_editors()

  if not api.tree.is_visible() then
    api.tree.toggle({ focus = false })
  end
end

-- Coalesces bursts of events (e.g. closing every buffer) into one check.
local function debounced(fn)
  local pending = false
  return function()
    if pending then
      return
    end
    pending = true
    vim.schedule(function()
      pending = false
      fn()
    end)
  end
end

local group = vim.api.nvim_create_augroup("filetree_layout", { clear = true })

-- Deferred so auto-session's own VimEnter restore has finished.
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    vim.schedule(on_startup)
  end,
})

local schedule_keep_editor = debounced(keep_editor)
vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(args)
    local win = tonumber(args.match)
    if not win or not vim.api.nvim_win_is_valid(win) or is_floating(win) then
      return
    end

    for _, other in ipairs(tiled_windows()) do
      if other ~= win and is_sidebar(other) and not sidebar_widths[other] then
        sidebar_widths[other] = vim.api.nvim_win_get_width(other)
      end
    end
    schedule_keep_editor()
  end,
})

-- Only listed buffers fire BufDelete, so wiping the dashboard itself doesn't retrigger this.
vim.api.nvim_create_autocmd("BufDelete", {
  group = group,
  callback = debounced(fill_blank_editors),
})

-- Replaces nvim-tree's directory hijack, which would fill the current window with the tree.
vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function(args)
    if vim.v.vim_did_enter == 0 or vim.g.SessionLoad == 1 or not is_directory(args.buf) then
      return
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end
      local dir = replace_directory(args.buf)
      api.tree.open({ path = dir })
      api.tree.change_root(dir)
    end)
  end,
})

-- Quitting the last editor window closes the sidebars too, so Neovim exits instead of leaving them full-screen.
vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  callback = function()
    local current = vim.api.nvim_get_current_win()
    if is_floating(current) or is_sidebar(current) then
      return
    end

    local others = {}
    for _, win in ipairs(tiled_windows()) do
      if win ~= current then
        if not is_sidebar(win) then
          return
        end
        table.insert(others, win)
      end
    end
    for _, win in ipairs(others) do
      vim.api.nvim_win_close(win, true)
    end
  end,
})
