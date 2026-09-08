{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs.lib) attrsToList concatMapStringsSep;
    in
    {
      apps = {
        report-sizes =
          let
            configurations = concatMapStringsSep "\n" (config: ''
              echo "| \`${config.name}\` | $(
                nix path-info --json --json-format 1 --closure-size ${config.value.activationPackage} \
                  | jq -r 'to_entries | first | .value.closureSize' | numfmt --to=si --suffix=B
              ) |"
            '') (attrsToList self.homeConfigurations);
            script = pkgs.writeShellApplication {
              name = "report";
              runtimeInputs = [
                pkgs.nix
                pkgs.jq
                pkgs.coreutils
              ];
              text = ''
                echo "# homeConfigurations sizes"

                echo "| Configuration | Size |"
                echo "| :-- | :-- |"
                ${configurations}
              '';
            };
          in
          {
            type = "app";
            program = "${script}/bin/report";
          };

        apply =
          let
            script = pkgs.writeShellApplication {
              name = "apply";
              runtimeInputs = [ pkgs.nix ];
              text = ''
                source "${../scripts/lib.sh}";
                CONFIGURATION="$(detect_configuration)"
                export CONFIGURATION

                echo "⚙️  Applying new configuration for $CONFIGURATION..."
                export HOME_MANAGER_BACKUP_EXT="backup"
                nix run --accept-flake-config .#homeConfigurations."$CONFIGURATION".activationPackage

                echo "🧹 Cleaning up..."
                nix-collect-garbage -d
              '';
            };
          in
          {
            type = "app";
            program = "${script}/bin/apply";
          };
      };
    };
}
