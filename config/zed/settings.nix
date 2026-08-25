{ config, ... }: {
  auto_install_extensions = {
    catppuccin-icons = true;
    nix = true;
    html = true;
    lua = true;
    xml = true;
    csharp = true;
    zig = true;
    zed-legacy-themes = true;
  };

  edit_predictions = {
    mode = "eager";
    provider = "copilot";
    allow_data_collection = "no";
    copilot = {
      proxy = null;
      proxy_no_verify = null;
      enterprise_uri = null;
      enable_next_edit_suggestions = false;
    };
  };

  agent = {
    enable_feedback = false;
    default_profile = "write";
    dock = "left";
    inline_assistant_model = {
      provider = "copilot_chat";
      model = "claude-sonnet-4.6";
    };
    default_model = {
      provider = "copilot_chat";
      model = "claude-sonnet-4.6";
    };
  };

  agent_servers = {
    "oh-my-pi" = {
      type = "custom";
      # TODO: figure out something better than this hardcoded path
      command = "${config.mdarocha.llm-agents.oh-my-pi.package}/bin/omp";
      args = [
        "--mode"
        "acp"
        "--approval-mode"
        "yolo"
      ];
      env = { };
    };
    "oh-my-pi (no sandbox)" = {
      type = "custom";
      command = "${config.mdarocha.llm-agents.oh-my-pi.package-nosandbox}/bin/omp-nosandbox";
      args = [
        "--mode"
        "acp"
        "--approval-mode"
        "yolo"
      ];
      env = { };
    };
  };

  project_panel.dock = "left";
  outline_panel.dock = "left";
  collaboration_panel = {
    dock = "left";
    button = false;
  };
  git_panel.dock = "left";

  autosave = "on_window_change";
  calls.mute_on_join = true;

  restore_on_startup = "last_session";
  base_keymap = "VSCode";
  format_on_save = "modifications";

  telemetry = {
    metrics = false;
    diagnostics = false;
  };

  preferred_line_length = 120;
  load_direnv = "shell_hook";
  cursor_blink = false;
  vim_mode = true;
  which_key.enabled = true;

  ui_font_size = 16;
  buffer_font_size = 14;
  ui_font_family = ".SystemUIFont";
  buffer_font_family = "Hack Nerd Font";

  theme = {
    mode = "system";
    light = "Zed Legacy: Solarized Light";
    dark = "Zed Legacy: Solarized Dark";
  };

  icon_theme = {
    mode = "system";
    dark = "Catppuccin Macchiato";
    light = "Catppuccin Macchiato";
  };

  git = {
    inline_blame = {
      enabled = false;
    };
  };

  wrap_guides = [
    80
    120
  ];

  scrollbar = {
    axes = {
      horizontal = false;
    };
  };

  tab_size = 4;

  tab_bar = {
    show = true;
    show_nav_history_buttons = false;
  };

  tabs = {
    file_icons = true;
  };

  terminal = {
    font_family = "Hack Nerd Font Mono";
    font_size = 14;
    line_height = "comfortable";
    shell = {
      program = "${config.home.homeDirectory}/.nix-profile/bin/zsh";
    };
    toolbar = {
      breadcrumbs = false;
    };
  };

  file_types = {
    XML = [
      "csproj"
      "fsproj"
      "props"
    ];
  };

  lsp = {
    nil = {
      settings = {
        nix = {
          flake = {
            autoArchive = false;
          };
        };
      };
    };
    omnisharp = {
      settings = {
        fileOptions = {
          systemExcludeSearchPatterns = [ ];
          excludeSearchPatterns = [
            "**/*.*"
            "!**/*.sln"
            "!**/*.csproj"
            "!**/*.cs"
          ];
        };
      };
    };
    vtsls = {
      settings = {
        javascript.updateImportsOnFileMove.enabled = "always";
        typescript.updateImportsOnFileMove.enabled = "always";
      };
    };
  };

  languages = {
    JSON = {
      tab_size = 2;
    };
    JSONC = {
      tab_size = 2;
    };
    YAML = {
      tab_size = 2;
    };
    XML = {
      tab_size = 2;
    };
    Nix = {
      tab_size = 2;
      language_servers = [
        "nil"
        "!nixd"
      ];
    };
    Lua = {
      tab_size = 2;
    };
  };

  # managed-config audit decisions (see .omp/commands/managed-config-audit.md)
  # - agent.tool_permissions: intentionally left unmanaged; skip in future audits.
  # - agent.default_model.enable_thinking/effort: intentionally left unmanaged; skip in future audits.
}
