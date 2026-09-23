-- Resolve the file's Git root so commits work from nested directories.
vim.api.nvim_create_user_command("OmpCommit", function()
  local root = vim.fs.root(0, ".git")
  if not root then
    vim.notify("OmpCommit: no git root found", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(vim.g.mdarocha_tools.omp) ~= 1 then
    vim.notify("OmpCommit: omp executable not found", vim.log.levels.WARN)
    return
  end
  Snacks.terminal({ vim.g.mdarocha_tools.omp, "commit" }, {
    cwd = root,
    win = { position = "bottom" },
  })
  vim.cmd("startinsert")
end, { desc = "Run omp commit in the repository root" })

-- BufferLine's cycle skips windows outside its filtered buffer list (sidebars, terminals, help, quickfix); reroute to a listed buffer first.
local function cycle_buffer_tab(direction)
  local bufferline = require("bufferline")
  local elements = bufferline.get_elements().elements
  if #elements == 0 then
    return
  end

  local listed = {}
  for _, element in ipairs(elements) do
    listed[element.id] = true
  end

  if not listed[vim.api.nvim_get_current_buf()] then
    local moved = false
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if listed[vim.api.nvim_win_get_buf(win)] then
        vim.api.nvim_set_current_win(win)
        moved = true
        break
      end
    end
    if not moved then
      -- No file window to reuse; split instead of replacing the special pane's buffer.
      vim.cmd("rightbelow vsplit")
      bufferline.go_to(direction > 0 and 1 or #elements, true)
      return
    end
  end

  for _ = 1, vim.v.count1 do
    bufferline.cycle(direction)
  end
end

vim.keymap.set("n", "gt", function() cycle_buffer_tab(1) end, { desc = "Next buffer tab" })
vim.keymap.set("n", "gT", function() cycle_buffer_tab(-1) end, { desc = "Previous buffer tab" })
