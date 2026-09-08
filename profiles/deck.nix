{
  imports = [
    ./common/generic-linux.nix
    ./common/desktop.nix
  ];

  mdarocha.zed.configDir = "$HOME/.var/app/dev.zed.Zed/config/zed";
  programs.git.settings.ghq.root = "~/sdcard/projects";

  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share"
    "\${HOME}/.local/share/flatpak/exports/share"
  ];

  home = {
    username = "deck";
    homeDirectory = "/home/deck";
  };
}
