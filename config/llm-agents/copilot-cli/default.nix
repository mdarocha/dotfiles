{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;
  copilotCli = cfg.copilot-cli;

  # patchelf >= 0.18 corrupts the Node SEA blob when setting rpath; the wrapper's LD_LIBRARY_PATH covers it.
  package = pkgs.llm-agents.copilot-cli.overrideAttrs {
    postInstall = ''
      install -m755 copilot "$out/lib/copilot-cli/copilot"
      patchelf --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
        "$out/lib/copilot-cli/copilot"
    '';
  };

  wrapped = cfg.wrapper {
    name = "copilot";
    home = ".copilot";
    program = "${package}/bin/copilot";
  };
in
{
  options.mdarocha.llm-agents.copilot-cli.enable = lib.mkEnableOption "GitHub Copilot CLI";

  config = lib.mkIf copilotCli.enable {
    home.packages = [ wrapped ];

    home.file = lib.mkMerge [
      {
        ".copilot/AGENTS.md".text = lib.concatStringsSep "\n" [
          cfg.instructions
          cfg.environment.instructions
          (cfg.networkLogInstructions ".copilot")
        ];
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".copilot/skills/${name}" { source = dir; }
      ) cfg.skills)
    ];
  };
}
