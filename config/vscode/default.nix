{ config, pkgs, lib, ... }:

# Configures an existing VS Code instance.
# Currently only supports running in a Github Codespace instance
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  cfg = config.mdarocha.vscode;

  json = pkgs.formats.json { };
  configFile = json.generate "settings.json" cfg.settings;
in
{
  imports = [ ./settings.nix ];

  options.mdarocha.vscode = {
    enable = mkEnableOption "vscode";

    extensions = mkOption {
      default = [ ];
      type = types.listOf types.str;
      description = ''
        A list of VS Code extensions to install.
      '';
    };

    settings = mkOption {
      default = { };
      type = json.type;
      description = ''
        A set of VS Code settings to apply.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.activation.configure-vscode = lib.hm.dag.entryAfter[ "writeBoundary " ] ''
      if [[ "''${CODESPACES:-}" != "true" ]]; then
        echo "This module supports only Github Codespaces."
        exit 1
      fi

      # The first time this script is executed, the Codespace container is in the process
      # of being setup. That means that the `code` cli and related functionality to communicate
      # with the VSCode instance are not setup yet.
      # To work around this, we generate a script file - /tmp/dotfiles-setup-codespace-vscode.sh,
      # and execute it in the default .bashrc, so that it runs when the user opens the terminal
      # in VSCode, where the needed environment variables are setup.
      # A marker file prevents duplicate execution.
      # It's VERY hacky, but it works...
      
      # Generate the setup script
      cat > /tmp/dotfiles-setup-codespace-vscode.sh << 'VSCODE_SETUP_EOF'
      #!/bin/bash

      # Set VSCODE_FOLDER based on VSCODE_GIT_ASKPASS_NODE
      if [[ -n "''${VSCODE_GIT_ASKPASS_NODE:-}" ]]; then
        VSCODE_FOLDER="''${VSCODE_GIT_ASKPASS_NODE%/node}"
        echo "VS Code folder detected: $VSCODE_FOLDER"
      else
        echo "Warning: VSCODE_GIT_ASKPASS_NODE not found, skipping VS Code setup"
        exit 0
      fi

      echo "Installing VS Code extensions..."
      for extension in ${lib.concatStringsSep " " cfg.extensions}; do
        "$VSCODE_FOLDER/bin/remote-cli/code" --install-extension "$extension"
      done

      echo "Merging VS Code settings..."
      settingsFile="$HOME/.vscode-remote/data/Machine/settings.json"
      newSettingsFile='${configFile}'

      if [ ! -f "$settingsFile" ]; then
        echo "Cannot find VS Code settings file at $settingsFile, skipping settings merge."
        exit 0
      fi
      
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settingsFile" "$newSettingsFile" > "$settingsFile.tmp"

      # removing the marker lets VS Code accept the new settings
      rm -rf "$HOME/.vscode-remote/data/Machine/.writeMachineSettingsMarker" || true
      mv "$settingsFile.tmp" "$settingsFile"

      echo "VS Code setup complete."
      
      # Remove this script to prevent duplicate execution
      rm /tmp/dotfiles-setup-codespace-vscode.sh
      VSCODE_SETUP_EOF

      chmod +x /tmp/dotfiles-setup-codespace-vscode.sh
    '';

    programs.bash.bashrcExtra = ''
      # VS Code Codespaces setup
      if [[ -f /tmp/dotfiles-setup-codespace-vscode.sh ]]; then
        /tmp/dotfiles-setup-codespace-vscode.sh
      fi
    '';
  };
}