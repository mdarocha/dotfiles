-- vtsls exposes these as protocol extensions rather than standard LSP methods.
local function vtsls_client()
    local client = vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })[1]
    if not client then
        vim.notify("vtsls: no attached client", vim.log.levels.WARN)
    end
    return client
end

vim.api.nvim_create_user_command("VtsOrganizeImports", function()
    local client = vtsls_client()
    if not client then
        return
    end
    client:exec_cmd({
        command = "typescript.organizeImports",
        arguments = { vim.uri_from_bufnr(0) },
    }, { bufnr = 0 })
end, { desc = "vtsls: organize imports" })

vim.api.nvim_create_user_command("VtsSourceDefinition", function()
    local client = vtsls_client()
    if not client then
        return
    end
    local position = vim.lsp.util.make_position_params(0, client.offset_encoding).position
    client:exec_cmd({
        command = "typescript.goToSourceDefinition",
        arguments = { vim.uri_from_bufnr(0), position },
    }, { bufnr = 0 }, function(err, result)
        if err then
            vim.notify("vtsls: " .. err.message, vim.log.levels.ERROR)
            return
        end
        local items = vim.tbl_map(function(loc)
            return { file = loc.filename, pos = { loc.lnum, loc.col - 1 }, line = loc.text }
        end, vim.lsp.util.locations_to_items(result or {}, client.offset_encoding))
        Snacks.picker.pick({
            title = "Source Definitions",
            items = items,
            format = "file",
            auto_confirm = true,
            jump = { tagstack = true, reuse_win = true },
        })
    end)
end, { desc = "vtsls: go to source definition" })
