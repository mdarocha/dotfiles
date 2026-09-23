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
