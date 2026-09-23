# Git: Fugitive for :Git, Gitsigns for hunks, Diffview for reviews and merge
# conflicts, and :OmpCommit to run `omp commit` from the repository root.
{ pkgs, hmConfig, ... }:
let
  # Upstream hasn't fixed this deprecation; patch the plugin source at build time.
  patchedDiffview = pkgs.vimPlugins.diffview-nvim.overrideAttrs (old: {
    # Table-form vim.validate{} is deprecated (no upstream issue; see :h deprecated-0.11), patch in ./diffview-validate.patch
    patches = (old.patches or [ ]) ++ [ ./diffview-validate.patch ];
  });
in
{
  # Fugitive handles Git commands; Gitsigns and Diffview cover hunks and reviews.
  plugins = {
    gitsigns.enable = true;
    fugitive.enable = true;
    diffview = {
      enable = true;
      package = patchedDiffview;
    };
  };

  # Snacks.lazygit backend; the lazygit.nvim module itself stays disabled.
  extraPackagesAfter = [ pkgs.lazygit ];

  # omp-commit.lua reads the binary path from here.
  globals.mdarocha_tools.omp = "${hmConfig.mdarocha.llm-agents.oh-my-pi.package}/bin/omp";

  keymaps = [
    # Git status and review history deliberately open different views.
    {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>Git<CR>";
      options.desc = "Git status";
    }
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>DiffviewOpen<CR>";
      options.desc = "Diffview";
    }
    {
      mode = "n";
      key = "]c";
      action.__raw = "function() require('gitsigns').next_hunk() end";
      options.desc = "Next git hunk";
    }
    {
      mode = "n";
      key = "[c";
      action.__raw = "function() require('gitsigns').prev_hunk() end";
      options.desc = "Previous git hunk";
    }
    {
      mode = "n";
      key = "<leader>hs";
      action.__raw = "function() require('gitsigns').stage_hunk() end";
      options.desc = "Stage hunk";
    }
    {
      mode = "n";
      key = "<leader>hr";
      action.__raw = "function() require('gitsigns').reset_hunk() end";
      options.desc = "Reset hunk";
    }
    {
      mode = "n";
      key = "<leader>hp";
      action.__raw = "function() require('gitsigns').preview_hunk() end";
      options.desc = "Preview hunk";
    }
    {
      mode = "n";
      key = "<leader>hb";
      action.__raw = "function() require('gitsigns').blame_line({ full = true }) end";
      options.desc = "Blame line";
    }
    {
      mode = "n";
      key = "<leader>oc";
      action = "<cmd>OmpCommit<CR>";
      options.desc = "omp commit";
    }
  ];

  extraConfigLua = builtins.readFile ./omp-commit.lua;
}
