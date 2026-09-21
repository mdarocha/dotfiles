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
                ../scripts/claude-code-web-nix.sh
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

        "run-packages" =
          let
            homePath =
              (inputs.home-manager.lib.homeManagerConfiguration {
                extraSpecialArgs = { inherit inputs; };
                pkgs = self.homeConfigurations.wsl.pkgs;
                modules = [
                  inputs.nixvim.homeModules.nixvim
                  ../config
                  (
                    { lib, ... }:
                    let
                      inherit (lib) mkDefault;
                    in
                    {
                      home = {
                        username = mkDefault "marek";
                        homeDirectory = mkDefault "/home/marek";
                      };
                    }
                  )
                  {
                    mdarocha.llm-agents = {
                      copilot-cli.enable = true;
                      claude-code.enable = true;
                      cursor-agent.enable = true;
                      oh-my-pi.enable = true;
                    };
                  }
                ];
              }).config.home.path;
          in
          pkgs.runCommand "run-packages" { } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"

            for cmd in git zsh gh copilot claude cursor-agent omp-nosandbox; do
              if [ ! -x "${homePath}/bin/$cmd" ]; then
                echo "missing executable in Home Manager profile: $cmd" >&2
                exit 1
              fi

              "${homePath}/bin/$cmd" --version
            done

            # The sandboxed omp launches bubblewrap, which cannot nest inside the
            # Nix build sandbox, so only its presence is checked here.
            if [ ! -x "${homePath}/bin/omp" ]; then
              echo "missing executable in Home Manager profile: omp" >&2
              exit 1
            fi

            touch "$out"
          '';
      };
    };
}
