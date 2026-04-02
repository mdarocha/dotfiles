{ pkgs, ... }:

# Configures an existing Ghostty installation. Ghostty itself must be installed
# separately (e.g. system package manager, AppImage, Flatpak).
{
  programs.ghostty = {
    enable = true;
    package = null;
    systemd.enable = false;
    enableZshIntegration = true;

    settings = {
      command = "${pkgs.zsh}/bin/zsh";
      # No bare "Solarized Dark" theme exists; this is the canonical theme name.
      theme = "iTerm2 Solarized Dark";
      font-family = "Hack Nerd Font";
      cursor-style = "block";
    };
  };
}
