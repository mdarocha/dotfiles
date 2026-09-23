# Symbol outline: Aerial sidebar on the right that follows the active buffer.
{ ... }:
{
  # Follow the active editor buffer while keeping the outline at the edge.
  plugins.aerial = {
    enable = true;
    settings = {
      backends = [
        "treesitter"
        "lsp"
        "markdown"
        "man"
      ];
      attach_mode = "global";
      filter_kind = false;
      layout = {
        placement = "edge";
        default_direction = "prefer_right";
        min_width = 24;
        max_width = [
          40
          0.2
        ];
        resize_to_content = true;
      };
      nerd_font = true;
      show_guides = true;
      highlight_mode = "split_width";
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>ss";
      action.__raw = "function() require('aerial').open({ focus = true }) end";
      options.desc = "Focus outline";
    }
    {
      mode = "n";
      key = "<A-r>";
      action.__raw = "function() require('aerial').toggle() end";
      options.desc = "Toggle outline";
    }
  ];
}
