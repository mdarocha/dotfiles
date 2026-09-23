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

-- Pyright reads the interpreter path once at startup.
vim.api.nvim_create_autocmd("User", {
    pattern = "VenvSelectPostActivate",
    callback = function()
        vim.cmd("lsp restart pyright")
    end,
})
