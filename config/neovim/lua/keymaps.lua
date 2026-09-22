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
