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

  # Import default configurations
  defaultSettings = import ./settings.nix;
  defaultKeymap = import ./keymap.nix;

  # Merge defaults with user-provided options
  mergedSettings = recursiveUpdate defaultSettings cfg.settings;
  mergedKeymap = defaultKeymap ++ cfg.keymap;

  # Generate JSON files
  settingsFile = json.generate "settings.json" mergedSettings;
  keymapFile = json.generate "keymap.json" mergedKeymap;
in
{
  options.mdarocha.zed = {
    enable = mkEnableOption "zed editor configuration";

    settings = mkOption {
      default = { };
      type = json.type;
      description = ''
        A set of Zed settings to apply. These will be deep merged with the default settings.
      '';
    };

    keymap = mkOption {
      default = [ ];
      type = types.listOf json.type;
      description = ''
        A list of Zed keymap configurations to apply. These will be appended to the default keymap.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.activation.configure-zed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Configuring Zed editor..."

      # Copy settings.json
      echo "Installing Zed settings..."
      cp "${settingsFile}" "$HOME/settings.json"

      # Copy keymap.json
      echo "Installing Zed keymap..."
      cp "${keymapFile}" "$HOME/keymap.json"

      echo "Zed configuration complete."
    '';
  };
}
