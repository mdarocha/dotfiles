# Shared bash helpers for home-manager activation scripts that update part
# of a config file owned by another tool (an editor, an agent) without
# clobbering settings that tool's own UI wrote outside of Nix. Nix always
# wins on conflicts; the previous file is backed up before being replaced.
{ pkgs }:
''
  # ---------------------------------------------------------------------------
  # strip_jsonc EXISTING_FILE
  #
  # Some tools write JSONC: full-line `//` comments and trailing commas before
  # a closing `}`/`]`, neither of which jq's strict JSON parser accepts.
  # Strips both so the result parses as plain JSON. Printed to stdout.
  # ---------------------------------------------------------------------------
  strip_jsonc() {
    grep -v '^\s*//' "$1" | sed -e ':a' -e 'N' -e '$!ba' -e 's/,\([[:space:]]*\n[[:space:]]*[]}]\)/\1/g'
  }

  # ---------------------------------------------------------------------------
  # _config_diff_warn LABEL NIX_JSON EXISTING_JSON BACKUP
  #
  # Warns when the existing file has top-level keys Nix doesn't define, and
  # when Nix overwrote a top-level key whose value differed from the existing
  # one. Both inputs must already be plain JSON.
  # ---------------------------------------------------------------------------
  _config_diff_warn() {
    local label="$1" nix_json="$2" existing_json="$3" backup="$4"

    local only_in_existing
    only_in_existing=$(${pkgs.jq}/bin/jq -r -n \
      --slurpfile nix "$nix_json" \
      --slurpfile old "$existing_json" \
      '(($old[0] // {}) | keys_unsorted) - (($nix[0] // {}) | keys_unsorted) | .[]')

    if [ -n "$only_in_existing" ]; then
      echo "WARNING: $label: the following top-level keys exist in the current file but are not defined by Nix (they are preserved):"
      while IFS= read -r key; do
        echo "  - $key"
      done <<< "$only_in_existing"
    fi

    local overwritten
    overwritten=$(${pkgs.jq}/bin/jq -r -n \
      --slurpfile nix "$nix_json" \
      --slurpfile old "$existing_json" \
      '($nix[0] // {} | keys_unsorted) as $nk |
       ($old[0] // {}) as $o | ($nix[0] // {}) as $n |
       $nk[] | select($o[.] != null and $o[.] != $n[.])')

    if [ -n "$overwritten" ]; then
      echo "WARNING: $label: Nix overwrote the following top-level keys from the current file (backup: $backup):"
      while IFS= read -r key; do
        echo "  - $key"
      done <<< "$overwritten"
    fi
  }

  # ---------------------------------------------------------------------------
  # merge_json_objects LABEL NIX_FILE EXISTING_FILE DEST BACKUP_SUFFIX
  #
  # Deep-merges two JSON(C) object files (Nix wins on conflicts). Backs up
  # EXISTING_FILE to EXISTING_FILE.BACKUP_SUFFIX before writing DEST.
  # ---------------------------------------------------------------------------
  merge_json_objects() {
    local label="$1" nix_file="$2" existing_file="$3" dest="$4" backup_suffix="$5"

    if [ ! -f "$existing_file" ] || [ ! -s "$existing_file" ]; then
      ${pkgs.jq}/bin/jq --tab '.' "$nix_file" > "$dest"
      return 0
    fi

    local backup="''${existing_file}.''${backup_suffix}"
    cp "$existing_file" "$backup"

    local existing_json
    existing_json=$(mktemp)
    strip_jsonc "$existing_file" > "$existing_json"

    _config_diff_warn "$label" "$nix_file" "$existing_json" "$backup"

    local tmp
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --tab -n \
      --slurpfile old "$existing_json" \
      --slurpfile nix "$nix_file" \
      '($old[0] // {}) * ($nix[0] // {})' > "$tmp" && mv "$tmp" "$dest"
  }

  # ---------------------------------------------------------------------------
  # merge_yaml_objects LABEL NIX_FILE EXISTING_FILE DEST BACKUP_SUFFIX
  #
  # Same deep-merge as merge_json_objects, for plain YAML files. Converts
  # through JSON internally, so any comments in EXISTING_FILE are lost -
  # don't point this at a file whose hand-written comments matter.
  # ---------------------------------------------------------------------------
  merge_yaml_objects() {
    local label="$1" nix_file="$2" existing_file="$3" dest="$4" backup_suffix="$5"

    if [ ! -f "$existing_file" ] || [ ! -s "$existing_file" ]; then
      ${pkgs.yq-go}/bin/yq -P '.' "$nix_file" > "$dest"
      return 0
    fi

    local backup="''${existing_file}.''${backup_suffix}"
    cp "$existing_file" "$backup"

    local nix_json existing_json
    nix_json=$(mktemp)
    existing_json=$(mktemp)
    ${pkgs.yq-go}/bin/yq -o=json '.' "$nix_file" > "$nix_json"
    ${pkgs.yq-go}/bin/yq -o=json '.' "$existing_file" > "$existing_json"

    _config_diff_warn "$label" "$nix_json" "$existing_json" "$backup"

    local tmp
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq -n \
      --slurpfile old "$existing_json" \
      --slurpfile nix "$nix_json" \
      '($old[0] // {}) * ($nix[0] // {})' | ${pkgs.yq-go}/bin/yq -P '.' - > "$tmp" && mv "$tmp" "$dest"
  }

  # ---------------------------------------------------------------------------
  # replace_json_array LABEL NIX_FILE EXISTING_FILE DEST BACKUP_SUFFIX
  #
  # Replaces DEST with NIX_FILE (arrays cannot be meaningfully merged). Warns
  # when the existing file differs from the Nix-managed version.
  # ---------------------------------------------------------------------------
  replace_json_array() {
    local label="$1" nix_file="$2" existing_file="$3" dest="$4" backup_suffix="$5"

    if [ ! -f "$existing_file" ] || [ ! -s "$existing_file" ]; then
      ${pkgs.jq}/bin/jq --tab '.' "$nix_file" > "$dest"
      return 0
    fi

    local backup="''${existing_file}.''${backup_suffix}"
    cp "$existing_file" "$backup"

    local existing_json
    existing_json=$(mktemp)
    strip_jsonc "$existing_file" > "$existing_json"

    if ! ${pkgs.jq}/bin/jq -n \
        --slurpfile nix "$nix_file" \
        --slurpfile old "$existing_json" \
        '($nix[0] // []) == ($old[0] // [])' | grep -q true; then
      echo "WARNING: $label: the existing file differs from the Nix-managed version and has been replaced (backup: $backup)"
    fi

    ${pkgs.jq}/bin/jq --tab '.' "$nix_file" > "$dest"
  }
''
