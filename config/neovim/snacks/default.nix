# snacks.nvim: pickers, the bottom terminal, notifications, image previews,
# Zen mode, indent guides, and the status column.
{ pkgs, ... }:
let
  # Upstream hasn't fixed this deprecation; patch the plugin source at build time.
  patchedSnacks = pkgs.vimPlugins.snacks-nvim.overrideAttrs (old: {
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

  # Every terminal shortcut opens the same bottom split.
  bottomTerminal = ''
    function()
      Snacks.terminal(nil, { win = { position = "bottom" } })
    end
  '';
in
{
  # Snacks keeps temporary UI out of the dedicated file and symbol panes.
  plugins.snacks = {
    enable = true;
    package = patchedSnacks;
    settings = {
      bigfile.enabled = true;
      notifier = {
        enabled = true;
        style = "compact";
        timeout = 2500;
        padding = true;
        filter.__raw = ''
          function(notif)
            if notif.title == "Snacks" then
              notif.title = nil
            end
            return true
          end
        '';
      };
      quickfile.enabled = true;
      statuscolumn.enabled = true;
      words.enabled = true;
      explorer.enabled = false;
      indent = {
        enabled = true;
        scope.enabled = false;
        chunk.enabled = false;
      };
      picker = {
        enabled = true;
        ui_select = true;
        # ffi.load("sqlite3") has no RPATH; point it at Nix's build.
        db.sqlite3_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
      };
      terminal = {
        enabled = true;
        win = {
          position = "bottom";
          height = 0.32;
          wo.statusline = "   Terminal";
          wo.winbar = "";
        };
      };
      image.enabled = true;
    };
  };

  extraPackagesAfter = with pkgs; [
    # File and content search for pickers.
    ripgrep
    fd

    # Converts images for snacks.image display.
    imagemagick

    # PDF, LaTeX, and Mermaid rendering for snacks.image.
    ghostscript
    tectonic
    mermaid-cli
  ];

  keymaps = [
    # Alt shortcuts reach persistent panes without replacing Vim's split keys.
    {
      mode = "n";
      key = "<A-c>";
      action.__raw = "function() Snacks.zen() end";
      options.desc = "Toggle zen mode";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<A-b>";
      action.__raw = bottomTerminal;
      options.desc = "Bottom terminal";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<C-`>";
      action.__raw = bottomTerminal;
      options.desc = "Bottom terminal";
    }
    {
      mode = "n";
      key = "g/";
      action.__raw = "function() Snacks.picker.grep() end";
      options.desc = "Search all files";
    }
    {
      mode = "n";
      key = "<C-p>";
      action.__raw = "function() Snacks.picker.files() end";
      options.desc = "Find files";
    }
    {
      mode = "n";
      key = "<leader>sf";
      action.__raw = "function() Snacks.picker.files() end";
      options.desc = "Find files";
    }
    {
      mode = "n";
      key = "<leader>sg";
      action.__raw = "function() Snacks.picker.grep() end";
      options.desc = "Live grep";
    }
    {
      mode = "n";
      key = "<leader>sb";
      action.__raw = "function() Snacks.picker.buffers() end";
      options.desc = "Buffers";
    }
    {
      mode = "n";
      key = "<leader>sS";
      action.__raw = "function() Snacks.picker.lsp_workspace_symbols() end";
      options.desc = "Workspace symbols";
    }
    {
      mode = "n";
      key = "<leader>sd";
      action.__raw = "function() Snacks.picker.diagnostics() end";
      options.desc = "Diagnostics";
    }
    {
      mode = "n";
      key = "<leader>sh";
      action.__raw = "function() Snacks.picker.help() end";
      options.desc = "Help";
    }
  ];
}
