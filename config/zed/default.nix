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

  configMergeLib = import ../lib/config-merge.nix { inherit pkgs; };

  mergedSettings = recursiveUpdate defaultSettings cfg.settings;
  mergedKeymap = defaultKeymap ++ cfg.keymap;

  settingsFile = json.generate "settings.json" mergedSettings;
  keymapFile = json.generate "keymap.json" mergedKeymap;
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
    home.activation.configure-zed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${configMergeLib}

      ZED_DIR="${cfg.configDir}"
      mkdir -p "$ZED_DIR"

      # Match the backup extension home-manager uses (exported by the apply script)
      BACKUP_SUFFIX="''${HOME_MANAGER_BACKUP_EXT:-backup}"

      echo "Configuring Zed editor (config dir: $ZED_DIR)..."

      merge_json_objects "zed settings" \
        "${settingsFile}" \
        "$ZED_DIR/settings.json" \
        "$ZED_DIR/settings.json" \
        "$BACKUP_SUFFIX"

      replace_json_array "zed keymap.json" \
        "${keymapFile}" \
        "$ZED_DIR/keymap.json" \
        "$ZED_DIR/keymap.json" \
        "$BACKUP_SUFFIX"

      echo "Zed configuration complete."
    '';
  };
}
