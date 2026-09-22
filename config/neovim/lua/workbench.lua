-- Edit .ipynb files as Python percent cells for Molten and the LSP.
-- Jupytext still writes changes back to the notebook.
require("jupytext").setup({
  style = "percent",
  output_extension = "py",
  force_ft = "python",
})
