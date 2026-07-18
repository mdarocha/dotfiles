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

  defaultSettings = import ./settings.nix;
  defaultKeymap = import ./keymap.nix;

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
      # ---------------------------------------------------------------------------
      # merge_json_objects NIX_FILE EXISTING_FILE DEST BACKUP_SUFFIX
      #
      # Deep-merges two JSON object files (NIX wins on conflicts).
      # Emits a warning when Nix overwrote an existing key, and when the existing
      # file had keys that Nix does not define.
      # The original file is backed up to EXISTING_FILE.BACKUP_SUFFIX before writing.
      # ---------------------------------------------------------------------------
      merge_json_objects() {
        local nix_file="$1"
        local existing_file="$2"
        local dest="$3"
        local backup_suffix="$4"

        if [ ! -f "$existing_file" ]; then
          ${pkgs.jq}/bin/jq --tab '.' "$nix_file" > "$dest"
          return 0
        fi

        local backup="''${existing_file}.''${backup_suffix}"
        cp "$existing_file" "$backup"

        # Keys present in existing but absent in nix
        local only_in_existing
        only_in_existing=$(${pkgs.jq}/bin/jq -r -n \
          --slurpfile nix "$nix_file" \
          --slurpfile old "$existing_file" \
          '($old[0] | keys_unsorted) - ($nix[0] | keys_unsorted) | .[]')

        if [ -n "$only_in_existing" ]; then
          echo "WARNING: zed settings: the following top-level keys exist in the current settings.json but are not defined by Nix (they are preserved):"
          while IFS= read -r key; do
            echo "  - $key"
          done <<< "$only_in_existing"
        fi

        # Keys where Nix differs from existing (Nix wins)
        local overwritten
        overwritten=$(${pkgs.jq}/bin/jq -r -n \
          --slurpfile nix "$nix_file" \
          --slurpfile old "$existing_file" \
          '($nix[0] | keys_unsorted) as $nk |
           $old[0] as $o | $nix[0] as $n |
           $nk[] | select($o[.] != null and ($o[.] | tojson) != ($n[.] | tojson))')

        if [ -n "$overwritten" ]; then
          echo "WARNING: zed settings: Nix overwrote the following top-level keys from the existing settings.json (backup: $backup):"
          while IFS= read -r key; do
            echo "  - $key"
          done <<< "$overwritten"
        fi

        # Merge: existing first, nix on top (nix wins)
        ${pkgs.jq}/bin/jq --tab -n \
          --slurpfile old "$existing_file" \
          --slurpfile nix "$nix_file" \
          '$old[0] * $nix[0]' > "$dest"
      }

      # ---------------------------------------------------------------------------
      # replace_json_array NIX_FILE EXISTING_FILE DEST BACKUP_SUFFIX
      #
      # Replaces DEST with NIX_FILE (arrays cannot be meaningfully merged).
      # Warns when the existing file had content that differs from the nix version.
      # The original file is backed up to EXISTING_FILE.BACKUP_SUFFIX before writing.
      # ---------------------------------------------------------------------------
      replace_json_array() {
        local nix_file="$1"
        local existing_file="$2"
        local dest="$3"
        local backup_suffix="$4"

        if [ ! -f "$existing_file" ]; then
          ${pkgs.jq}/bin/jq --tab '.' "$nix_file" > "$dest"
          return 0
        fi

        local backup="''${existing_file}.''${backup_suffix}"
        cp "$existing_file" "$backup"

        if ! ${pkgs.jq}/bin/jq -n \
            --slurpfile nix "$nix_file" \
            --slurpfile old "$existing_file" \
            '$nix[0] == $old[0]' | grep -q true; then
          echo "WARNING: zed keymap: the existing keymap.json differs from the Nix-managed version and has been replaced (backup: $backup)"
        fi

        ${pkgs.jq}/bin/jq --tab '.' "$nix_file" > "$dest"
      }

      ZED_DIR="${cfg.configDir}"
      mkdir -p "$ZED_DIR"

      # Match the backup extension home-manager uses (exported by the apply script)
      BACKUP_SUFFIX="''${HOME_MANAGER_BACKUP_EXT:-backup}"

      echo "Configuring Zed editor (config dir: $ZED_DIR)..."

      merge_json_objects \
        "${settingsFile}" \
        "$ZED_DIR/settings.json" \
        "$ZED_DIR/settings.json" \
        "$BACKUP_SUFFIX"

      replace_json_array \
        "${keymapFile}" \
        "$ZED_DIR/keymap.json" \
        "$ZED_DIR/keymap.json" \
        "$BACKUP_SUFFIX"

      echo "Zed configuration complete."
    '';
  };
}
