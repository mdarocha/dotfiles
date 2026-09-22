-- Default border for native floats without one; see :h 'winborder'.
vim.o.winborder = "rounded"

vim.diagnostic.config({
    float = { border = "rounded" },
})

-- On a warned line, K shows the diagnostic; clean lines retain LSP hover.
local function show_lsp_details()
    local _, window = vim.diagnostic.open_float({ scope = "line", header = "", focusable = true })
    if not window then
        vim.lsp.buf.hover()
    end
end

for _, key in ipairs({ "K", "<C-k>" }) do
    vim.keymap.set("n", key, show_lsp_details, { desc = "Diagnostic or hover" })
end
vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature help" })

-- LSP messages keep their server name; DEBUG logs stay below Fidget's INFO filter.
local message_levels = {
    [vim.lsp.protocol.MessageType.Error] = vim.log.levels.ERROR,
    [vim.lsp.protocol.MessageType.Warning] = vim.log.levels.WARN,
    [vim.lsp.protocol.MessageType.Info] = vim.log.levels.INFO,
    [vim.lsp.protocol.MessageType.Log] = vim.log.levels.DEBUG,
}

vim.lsp.handlers["window/showMessage"] = function(_, params, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    require("fidget").notify(params.message, message_levels[params.type] or vim.log.levels.INFO, {
        group = client and client.name or "LSP",
    })
end

-- Recompute the lualine server count after the client's attachment changes.
vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    callback = function()
        vim.schedule(function()
            require("lualine").refresh({ place = { "statusline" } })
        end)
    end,
})

-- roslyn.nvim appends --daemon-mode by default, which nixpkgs' roslyn-ls
-- (5.11.0) rejects.
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

-- vtsls exposes these as protocol extensions rather than standard LSP methods.
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

-- Pyright reads the interpreter path once at startup.
vim.api.nvim_create_autocmd("User", {
    pattern = "VenvSelectPostActivate",
    callback = function()
        vim.cmd("LspRestart pyright")
    end,
})
