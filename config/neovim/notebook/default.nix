# Python notebooks: Jupytext edits .ipynb files as `# %%` Python buffers; Molten runs the cells.
# Molten's Python packages come from pythonEnv (../default.nix) through python3_host_prog.
{ pkgs, ... }:
let
  # Upstream hasn't fixed this deprecation; patch the plugin source at build time.
  patchedJupytext = pkgs.vimPlugins.jupytext-nvim.overrideAttrs (old: {
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
  });

  # jupytext.nvim's .ipynb conversion CLI.
  jupytextCli = pkgs.python3.withPackages (ps: [ ps.jupytext ]);
in
{
  # Molten runs notebook cells after Jupytext opens them as Python buffers.
  plugins.molten = {
    enable = true;
    settings = {
      auto_open_output = true;
      image_provider = "snacks";
    };
  };

  extraPlugins = [ patchedJupytext ];
  extraPackagesAfter = [ jupytextCli ];

  keymaps = [
    # Molten re-evaluates the percent cells emitted by Jupytext.
    {
      mode = "n";
      key = "<localleader>mi";
      action = "<cmd>MoltenInit<CR>";
      options.desc = "Molten init kernel";
    }
    {
      mode = "n";
      key = "<localleader>rr";
      action = "<cmd>MoltenReevaluateCell<CR>";
      options.desc = "Rerun cell";
    }
    {
      mode = "n";
      key = "<localleader>rl";
      action = "<cmd>MoltenEvaluateLine<CR>";
      options.desc = "Run line";
    }
    {
      mode = "v";
      key = "<localleader>r";
      action = "<cmd>MoltenEvaluateVisual<CR>gv";
      options.desc = "Run selection";
    }
  ];

  # Edit .ipynb files as Python percent cells for Molten and the LSP.
  # Jupytext still writes changes back to the notebook.
  extraConfigLua = ''
    require("jupytext").setup({
      style = "percent",
      output_extension = "py",
      force_ft = "python",
    })
  '';
}
