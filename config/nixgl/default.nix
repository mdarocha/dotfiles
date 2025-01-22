{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mdarocha.nixgl;
in
{
  options.mdarocha.nixgl = {
    enable = mkEnableOption "nixGl";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixgl.nixGLIntel
      nixgl.nixVulkanIntel
    ];
  };
}
