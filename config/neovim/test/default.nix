# Tests: neotest with Python, Vitest, Rust, and .NET adapters behind one set of keys.
{ pkgs, ... }:
{
  # Neotest selects the adapter that matches the current language.
  plugins.neotest = {
    enable = true;
    adapters = {
      python.enable = true;
      vitest.enable = true;
      rust.enable = true;
      dotnet.enable = true;
    };
  };

  # dotnet test for neotest-dotnet.
  extraPackagesAfter = [ pkgs.dotnet-sdk_10 ];

  keymaps = [
    # The same keys use the Python, Rust, Vitest, or .NET adapter by filetype.
    {
      mode = "n";
      key = "<leader>tt";
      action.__raw = "function() require('neotest').run.run() end";
      options.desc = "Run nearest test";
    }
    {
      mode = "n";
      key = "<leader>tf";
      action.__raw = "function() require('neotest').run.run(vim.fn.expand('%')) end";
      options.desc = "Run file tests";
    }
    {
      mode = "n";
      key = "<leader>ts";
      action.__raw = "function() require('neotest').summary.toggle() end";
      options.desc = "Toggle test summary";
    }
    {
      mode = "n";
      key = "<leader>to";
      action.__raw = "function() require('neotest').output.open({ enter = true }) end";
      options.desc = "Open test output";
    }
  ];
}
