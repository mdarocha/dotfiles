# GitHub Copilot inline suggestions; <C-y> accepts (blink.cmp leaves it unmapped).
{ pkgs, ... }:
{
  plugins.copilot-lua = {
    enable = true;
    settings = {
      panel.enabled = false;
      suggestion = {
        enabled = true;
        auto_trigger = true;
        # Ghost text stays visible over the completion menu so <C-y> can take it.
        hide_during_completion = false;
        # Without a visible suggestion, <C-y> passes through instead of requesting one.
        trigger_on_accept = false;
        keymap = {
          accept = "<C-y>";
          dismiss = "<C-]>";
        };
      };
    };
  };

  # Copilot's language server runs on node.
  extraPackagesAfter = [ pkgs.nodejs ];
}
