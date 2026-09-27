local function attach_embedded(args)
    vim.api.nvim_buf_call(args.buf, function()
        require("otter").activate({ "bash", "lua", "python" })
    end)
end

vim.api.nvim_create_autocmd("FileType", { pattern = "nix", callback = attach_embedded })
-- otter only serves languages present at activation, so saves pick up newly added ones.
vim.api.nvim_create_autocmd("BufWritePost", { pattern = "*.nix", callback = attach_embedded })
