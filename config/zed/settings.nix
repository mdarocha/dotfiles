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

  project_panel.dock = "left";
  outline_panel.dock = "left";
  collaboration_panel.dock = "left";
  git_panel.dock = "left";

  autosave = "on_window_change";
  restore_on_startup = "last_session";
  base_keymap = "VSCode";

  telemetry = {
    metrics = false;
    diagnostics = false;
  };

  preferred_line_length = 120;
  load_direnv = "shell_hook";
  cursor_blink = false;
  vim_mode = true;
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
}
