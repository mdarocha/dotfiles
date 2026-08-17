{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    recursiveUpdate
    ;

  cfg = config.mdarocha.zed;

  json = pkgs.formats.json { };

  defaultSettings = import ./settings.nix { inherit config pkgs lib; };
  defaultKeymap = import ./keymap.nix { inherit config pkgs lib; };

  mergedSettings = recursiveUpdate defaultSettings cfg.settings;
  mergedKeymap = defaultKeymap ++ cfg.keymap;
in
{
  options.mdarocha.zed = {
    enable = mkEnableOption "zed editor configuration";

    configDir = mkOption {
      type = types.str;
      default = "$HOME/.var/app/dev.zed.Zed/config/zed";
      description = ''
        Path to the Zed configuration directory. Defaults to the Flatpak data
        path. Override for native installs or WSL (Windows Zed via /mnt/c).
      '';
    };

    settings = mkOption {
      default = { };
      type = json.type;
      description = ''
        Zed settings to deep-merge with the defaults.
      '';
    };

    keymap = mkOption {
      default = [ ];
      type = types.listOf json.type;
      description = ''
        Keymap entries appended to the default keymap.
      '';
    };
  };

  config = mkIf cfg.enable {
    mdarocha.managedConfigFiles = {
      zed-settings = {
        configDir = cfg.configDir;
        fileName = "settings.json";
        format = "json";
        label = "zed settings";
        value = mergedSettings;
      };
      zed-keymap = {
        configDir = cfg.configDir;
        fileName = "keymap.json";
        format = "json-array";
        label = "zed keymap.json";
        value = mergedKeymap;
      };
    };
  };
}
