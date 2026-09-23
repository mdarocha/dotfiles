{ pkgs }:
{
  # Upstream hasn't fixed these deprecations; patch vendored plugin sources at build time.

  plugins.snacks.package = pkgs.vimPlugins.snacks-nvim.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Dot-form LSP client methods deprecate at runtime: https://github.com/folke/snacks.nvim/issues/2839
      substituteInPlace lua/snacks/words.lua \
        --replace-fail \
          'client.supports_method("textDocument/documentHighlight", { bufnr = buf })' \
          'client:supports_method("textDocument/documentHighlight", { bufnr = buf })'
      substituteInPlace lua/snacks/rename.lua \
        --replace-fail \
          'client.supports_method("workspace/willRenameFiles")' \
          'client:supports_method("workspace/willRenameFiles")' \
        --replace-fail \
          'client.request_sync("workspace/willRenameFiles", changes, 1000, 0)' \
          'client:request_sync("workspace/willRenameFiles", changes, 1000, 0)' \
        --replace-fail \
          'client.supports_method("workspace/didRenameFiles")' \
          'client:supports_method("workspace/didRenameFiles")' \
        --replace-fail \
          'client.notify("workspace/didRenameFiles", changes)' \
          'client:notify("workspace/didRenameFiles", changes)'
    '';
  });

  plugins.lualine.package = pkgs.vimPlugins.lualine-nvim.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Table-form vim.validate{} is deprecated: https://github.com/nvim-lualine/lualine.nvim/issues/1399
      substituteInPlace lua/lualine/utils/fn_store.lua \
        --replace-fail \
          $'  vim.validate {\n    id = { id, \'n\' },\n    fn = { fn, \'f\' },\n  }' \
          $'  vim.validate("id", id, "number")\n  vim.validate("fn", fn, "function")' \
        --replace-fail \
          "vim.validate { id = { id, 'n' } }" \
          'vim.validate("id", id, "number")'
    '';
  });

  plugins.diffview.package = pkgs.vimPlugins.diffview-nvim.overrideAttrs (old: {
    # Table-form vim.validate{} is deprecated (no upstream issue; see :h deprecated-0.11), patch in ./diffview-validate.patch
    patches = (old.patches or [ ]) ++ [ ./diffview-validate.patch ];
  });

  # Patched here, not core.nix, so the postPatch convention stays in one file.
  extraPlugins = [
    (pkgs.vimPlugins.jupytext-nvim.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        # Table-form vim.validate{} is deprecated: https://github.com/GCBallesteros/jupytext.nvim/pull/34
        substituteInPlace lua/jupytext/init.lua \
          --replace-fail \
            'vim.validate({ config = { config, "table", true } })' \
            'vim.validate("config", config, "table", true)' \
          --replace-fail \
            $'  vim.validate({\n    style = { M.config.style, "string" },\n    output_extension = { M.config.output_extension, "string" },\n  })' \
            $'  vim.validate("style", M.config.style, "string")\n  vim.validate("output_extension", M.config.output_extension, "string")'
      '';
    }))
  ];
}
