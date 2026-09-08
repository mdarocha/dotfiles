{
  imports = [
    ./common/generic-linux.nix
    ./common/desktop.nix
  ];

  mdarocha.zed.configDir = "$HOME/.var/app/dev.zed.Zed/config/zed";
}
