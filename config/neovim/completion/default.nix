# Completion: blink.cmp menu for LSP, buffer, path, and snippet sources.
{ ... }:
{
  plugins.blink-cmp = {
    enable = true;
    settings = {
      # Arrow keys keep their usual behavior when completion is closed.
      # Tab accepts the menu; <C-y> belongs to Copilot alone.
      keymap = {
        preset = "default";
        "<Tab>" = [
          "select_and_accept"
          "snippet_forward"
          "fallback"
        ];
        "<C-y>" = false;
        "<Up>" = [
          "select_prev"
          "fallback"
        ];
        "<Down>" = [
          "select_next"
          "fallback"
        ];
      };
      cmdline.keymap = {
        preset = "cmdline";
        "<Up>" = [
          "select_prev"
          "fallback"
        ];
        "<Down>" = [
          "select_next"
          "fallback"
        ];
      };
      completion = {
        menu.border = "rounded";
        documentation.window.border = "rounded";
      };
      signature.window.border = "rounded";
    };
  };
}
