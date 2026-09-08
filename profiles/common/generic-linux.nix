{
  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };

  systemd.user.sessionVariables.LD_LIBRARY_PATH = "$HOME/.nix-profile/lib:\${LD_LIBRARY_PATH:-}";
}
