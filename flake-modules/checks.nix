{ self, inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = {
        shellcheck =
          let
            inherit (pkgs.lib.fileset) toSource unions;
          in
          pkgs.testers.shellcheck {
            name = "shellcheck";
            src = toSource {
              root = ../.;
              fileset = unions [
                ../install.sh
                ../scripts/lib.sh
                ../scripts/nix-daemon.initd
              ];
            };
          };

        homeConfigurations =
          let
            inherit (pkgs.lib) attrValues map;
            paths = map (config: config.activationPackage) (attrValues self.homeConfigurations);
          in
          pkgs.symlinkJoin {
            name = "home-configurations";
            inherit paths;
          };

        apps =
          let
            inherit (pkgs.lib) attrValues concatMapStringsSep;
            paths = concatMapStringsSep "\n" (app: app.program) (attrValues self.apps.${system});
          in
          pkgs.writeText "apps-check" paths;
        profile-selection = import ../tests/profile-selection.nix { inherit pkgs; };
        "nixos-activation" = import ../tests/nixos-activation.nix { inherit pkgs self; };

        "run-packages" =
          let
            homePath =
              (
                self.homeConfigurations.linux.extendModules {
                  modules = [ { mdarocha.llm-agents.sandbox.enable = false; } ];
                }
              ).config.home.path;
          in
          pkgs.runCommand "run-packages" { } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"

            for cmd in git zsh gh omp copilot omp-nosandbox copilot-nosandbox; do
              if [ ! -x "${homePath}/bin/$cmd" ]; then
                echo "missing executable in Home Manager profile: $cmd" >&2
                exit 1
              fi

              "${homePath}/bin/$cmd" --version
            done

            touch "$out"
          '';
      };
    };
}
