# Key hints: mini.clue shows the available <leader> mappings in a corner popup.
# Group names mirror the prefixes defined by the other modules.
{ ... }:
{
  # Prefix hints float in the corner instead of replacing the command line.
  plugins.mini = {
    enable = true;
    modules.clue = {
      triggers = [
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>";
        }
      ];
      clues = [
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>s";
          desc = "+search";
        }
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>g";
          desc = "+git";
        }
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>h";
          desc = "+git hunk";
        }
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>d";
          desc = "+debug";
        }
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>t";
          desc = "+test";
        }
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>o";
          desc = "+oh-my-pi";
        }
        {
          mode = [
            "n"
            "x"
          ];
          keys = "<Leader>b";
          desc = "+buffer";
        }
      ];
      window = {
        delay = 300;
        scroll_down = "<C-d>";
        scroll_up = "<C-u>";
        config = {
          anchor = "SE";
          row = "auto";
          col = "auto";
          width = "auto";
          border = "rounded";
        };
      };
    };
  };
}
