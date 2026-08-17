# Declarative interface for config files owned by another tool's own UI
# (an editor, an agent) rather than fully by home-manager: Nix deep-merges
# its managed defaults in, the tool's own edits outside of those keys are
# preserved, and the previous file is backed up before being replaced.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  formats = {
    json = pkgs.formats.json { };
    yaml = pkgs.formats.yaml { };
  };

  configMergeLib = import ./config-merge.nix { inherit pkgs; };

  cfg = config.mdarocha.managedConfigFiles;

  fileType = types.submodule (
    { name, ... }:
    {
      options = {
        configDir = mkOption {
          type = types.str;
          description = "Directory (may reference $HOME) the file lives in.";
        };

        fileName = mkOption {
          type = types.str;
          default = name;
          description = "File name within configDir.";
        };

        format = mkOption {
          type = types.enum [
            "json"
            "json-array"
            "yaml"
          ];
          default = "json";
          description = ''
            How to reconcile the Nix-managed content with whatever the tool
            itself already wrote to the file:
            - "json" / "yaml": deep-merge objects, Nix wins on conflicts.
            - "json-array": arrays can't be meaningfully merged, so the file
              is replaced outright.
          '';
        };

        value = mkOption {
          type = types.anything;
          description = "Nix-managed content to write/merge into the file.";
        };

        label = mkOption {
          type = types.str;
          default = name;
          description = "Human-readable label used in merge warnings.";
        };
      };
    }
  );

  mkEntry =
    name: file:
    let
      fmt = if file.format == "yaml" then formats.yaml else formats.json;
      generated = fmt.generate file.fileName file.value;
      mergeFn =
        {
          json = "merge_json_objects";
          yaml = "merge_yaml_objects";
          json-array = "replace_json_array";
        }
        .${file.format};
    in
    lib.nameValuePair "managed-config-file-${name}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${configMergeLib}

        DEST_DIR="${file.configDir}"
        mkdir -p "$DEST_DIR"
        DEST="$DEST_DIR/${file.fileName}"

        # Match the backup extension home-manager uses (exported by the apply script)
        BACKUP_SUFFIX="''${HOME_MANAGER_BACKUP_EXT:-backup}"

        ${mergeFn} "${file.label}" "${generated}" "$DEST" "$DEST" "$BACKUP_SUFFIX"
      ''
    );
in
{
  options.mdarocha.managedConfigFiles = mkOption {
    type = types.attrsOf fileType;
    default = { };
    description = ''
      Config files owned by another tool's own UI that Nix should deep-merge
      defaults into, à la home.file but merge- instead of replace-semantics.
    '';
  };

  config.home.activation = lib.mapAttrs' mkEntry cfg;
}
