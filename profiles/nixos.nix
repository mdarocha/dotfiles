{
  imports = [ ./common/desktop.nix ];

  targets.genericLinux = {
    enable = false;
    gpu.enable = false;
  };
}
