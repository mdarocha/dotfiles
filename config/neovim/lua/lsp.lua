local function format_on_save(args)
  local clients = vim.lsp.get_clients({ bufnr = args.buf })
  for _, client in ipairs(clients) do
    if client:supports_method("textDocument/formatting") then
      vim.lsp.buf.format({ async = false, bufnr = args.buf })
      return
    end
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = format_on_save,
})

vim.lsp.config("roslyn", {
  cmd = {
    "Microsoft.CodeAnalysis.LanguageServer",
    "--stdio",
    "--logLevel=Information",
    "--extensionLogDirectory=" .. vim.fn.stdpath("cache") .. "/roslyn",
  },
})

require("roslyn").setup({
  broad_search = true,
})

vim.api.nvim_create_user_command("VtsOrganizeImports", function()
  vim.lsp.buf.execute_command({
    command = "typescript.organizeImports",
    arguments = { vim.uri_from_bufnr(0) },
  })
end, { desc = "vtsls: organize imports" })

vim.api.nvim_create_user_command("VtsSourceDefinition", function()
  vim.lsp.buf.execute_command({
    command = "typescript.goToSourceDefinition",
    arguments = { vim.uri_from_bufnr(0), vim.lsp.util.make_position_params().position },
  })
end, { desc = "vtsls: go to source definition" })

vim.api.nvim_create_autocmd("User", {
  pattern = "VenvSelectPostActivate",
  callback = function()
    vim.cmd("LspRestart pyright")
  end,
})
