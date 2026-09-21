-- Percent cells so Molten sees the same markers in .ipynb and .py files.
require("jupytext").setup({
  style = "percent",
  output_extension = "py",
  force_ft = "python",
})
