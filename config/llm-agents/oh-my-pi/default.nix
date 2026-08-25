{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mdarocha.llm-agents;

  yaml = pkgs.formats.yaml { };

  defaultConfig = import ./config.nix { inherit config pkgs lib; };
  mergedConfig = lib.recursiveUpdate defaultConfig cfg.oh-my-pi.settings;

  # TODO read this from the ./rules directory instead of hardcoding it here.
  rules = {
    no-nix-store-source-search = ./rules/no-nix-store-source-search.md;
    no-filesystem-root-scan = ./rules/no-filesystem-root-scan.md;
    pr-fixes-one-per-line = ./rules/pr-fixes-one-per-line.md;
    minimal-comments = ./rules/minimal-comments.md;
  };
in
{
  options.mdarocha.llm-agents.oh-my-pi = {
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.omp/agent";
      description = ''
        Path to the oh-my-pi agent configuration directory.
      '';
    };

    settings = lib.mkOption {
      default = { };
      type = yaml.type;
      description = ''
        oh-my-pi config.yml settings to deep-merge with the defaults.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.sandbox.wrapPackages "omp" pkgs.llm-agents.omp;

    home.file = lib.mkMerge [
      {
        # oh-my-pi discovers AGENTS.md files via universal config discovery.
        ".omp/agent/AGENTS.md".text = cfg.common.agentInstructions;
      }
      (lib.mapAttrs' (
        name: dir: lib.nameValuePair ".omp/agent/skills/${name}" { source = dir; }
      ) cfg.common.skills)
      (lib.mapAttrs' (name: src: lib.nameValuePair ".omp/agent/rules/${name}.md" { source = src; }) rules)
    ];

    mdarocha.managedConfigFiles.oh-my-pi-config = {
      configDir = cfg.oh-my-pi.configDir;
      fileName = "config.yml";
      format = "yaml";
      label = "omp config";
      value = mergedConfig;
    };
  };
}
