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

  packages = cfg.sandbox.wrapPackages "omp" pkgs.llm-agents.omp;

  ompSpecificInstructions = ''
    # Git worktrees

    If you create git worktrees, always use the `~/.omp/wt` folder (the
    same folder the built-in `github` tool's `pr_checkout` op uses).

    Name each worktree directory `<slug>-<repo-hash>`, matching that same
    built-in convention (`<pr-number>-<repo-hash>`):
    - `<slug>`: a short, descriptive identifier for the work (issue/PR
      number, ticket id, or a brief kebab-case task descriptor) — not the
      branch name verbatim.
    - `<repo-hash>`: a 7-hex-character digest of the repository root path
      (e.g. `git rev-parse --show-toplevel | sha1sum | cut -c1-7`), so
      worktrees from different repos never collide inside the shared
      `~/.omp/wt` folder.
  '';
in
{
  options.mdarocha.llm-agents.oh-my-pi = {
    package = lib.mkOption {
      type = lib.types.package;
      default = packages.sandbox;
      description = ''
        oh-my-pi agent package.
      '';
    };

    package-nosandbox = lib.mkOption {
      type = lib.types.package;
      default = packages.no-sandbox;
      description = ''
        oh-my-pi agent package without sandboxing.
      '';
    };

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
    home.packages = [
      cfg.oh-my-pi.package
      cfg.oh-my-pi.package-nosandbox
    ];

    home.file = lib.mkMerge [
      {
        ".omp/agent/AGENTS.md".text = cfg.common.base + ompSpecificInstructions;

        ".omp/agent/extensions/sandbox-instructions.ts".text = ''
          import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

          const SANDBOX = ${builtins.toJSON cfg.common.sandbox};
          const NO_SANDBOX = ${builtins.toJSON cfg.common."no-sandbox"};

          export default function (pi: ExtensionAPI) {
            pi.setLabel("Sandbox Instructions");

            pi.on("before_agent_start", async (event) => {
              const extra = process.env.MDAROCHA_AGENT_SANDBOX === "1" ? SANDBOX : NO_SANDBOX;
              if (!extra.trim()) return undefined;

              // The returned array replaces the prompt wholesale, so carry the
              // current one over instead of returning the chunk alone.
              return {
                systemPrompt: [...event.systemPrompt, extra],
              };
            });
          }
        '';
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

    home.activation.download-omp-tiny-models =
      lib.mkIf
        (
          mergedConfig.providers ? tinyModel
          && mergedConfig.providers.tinyModel != null
          && mergedConfig.providers.tinyModel != "online"
        )
        (
          lib.hm.dag.entryAfter [ "managed-config-file-oh-my-pi-config" "reloadSystemd" ] ''
            run ${cfg.oh-my-pi.package-nosandbox}/bin/omp-nosandbox tiny-models download ${mergedConfig.providers.tinyModel}
          ''
        );
  };
}
