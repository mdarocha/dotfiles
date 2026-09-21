{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mdarocha.neovim;

  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pynvim
      jupyter-client
      ipykernel
      debugpy
    ]
  );
  jupytextCli = pkgs.python3.withPackages (ps: [ ps.jupytext ]);

  toolPaths = {
    omp = "${config.mdarocha.llm-agents.oh-my-pi.package}/bin/omp";
  };

  luaModules = [
    ./lua/options.lua
    ./lua/ui.lua
    ./lua/lsp.lua
    ./lua/workbench.lua
    ./lua/keymaps.lua
  ];
in
{
  options.mdarocha.neovim = {
    enable = mkEnableOption "neovim editor configuration";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;

      nixpkgs.useGlobalPackages = true;

      extraPackages = with pkgs; [
        ripgrep
        fd
        imagemagick
        nodejs
        netcoredbg
        vscode-js-debug
        lldb
        dotnet-sdk
        jupytextCli
        cargo
        rustc
        rustfmt
        pythonEnv
        roslyn-ls
      ];

      extraPlugins = with pkgs.vimPlugins; [
        solarized-nvim
        roslyn-nvim
        jupytext-nvim
      ];

      extraConfigLua = ''
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        vim.g.python3_host_prog = "${pythonEnv}/bin/python3"

        vim.g.mdarocha_tools = {
          omp = "${toolPaths.omp}",
        }
      ''
      + lib.concatMapStringsSep "\n" builtins.readFile luaModules;

      plugins = {
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
          grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
            bash
            c_sharp
            css
            html
            javascript
            json
            lua
            markdown
            markdown_inline
            nix
            python
            rust
            tsx
            typescript
            vim
            vimdoc
            xml
            yaml
            zig
          ];
          languageRegister.json = "jsonc";
        };

        blink-cmp.enable = true;

        lsp = {
          enable = true;
          servers = {
            nil_ls = {
              enable = true;
              settings.nix.flake.autoArchive = false;
            };
            lua_ls.enable = true;
            pyright.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
              installRustfmt = false;
            };
            vtsls = {
              enable = true;
              settings = {
                javascript.updateImportsOnFileMove.enabled = "always";
                typescript.updateImportsOnFileMove.enabled = "always";
              };
            };
            html.enable = true;
            cssls.enable = true;
            jsonls.enable = true;
            yamlls.enable = true;
            lemminx.enable = true;
            zls.enable = true;
          };
        };

        snacks = {
          enable = true;
          settings = {
            bigfile.enabled = true;
            notifier.enabled = true;
            quickfile.enabled = true;
            statuscolumn.enabled = true;
            words.enabled = true;
            indent.enabled = true;
            explorer.enabled = true;
            picker = {
              enabled = true;
              ui_select = true;
            };
            terminal.enabled = true;
            image.enabled = true;
          };
        };

        lualine = {
          enable = true;
          settings.options.theme = "solarized_dark";
        };

        which-key = {
          enable = true;
          settings.spec.__raw = ''
            {
              { "<leader>s", group = "search" },
              { "<leader>g", group = "git" },
              { "<leader>h", group = "git hunk" },
              { "<leader>d", group = "debug" },
              { "<leader>t", group = "test" },
              { "<leader>o", group = "oh-my-pi" },
            }
          '';
        };

        auto-session = {
          enable = true;
          settings = {
            auto_restore_last_session = true;
            bypass_save_filetypes = [
              "snacks_dashboard"
              "snacks_terminal"
              "prompt"
              "help"
            ];
          };
        };

        gitsigns.enable = true;
        neogit.enable = true;
        diffview.enable = true;

        copilot-lua = {
          enable = true;
          settings = {
            panel.enabled = false;
            suggestion = {
              enabled = true;
              auto_trigger = true;
              hide_during_completion = true;
              keymap = {
                accept = "<C-y>";
                dismiss = "<C-]>";
              };
            };
          };
        };

        render-markdown.enable = true;

        molten = {
          enable = true;
          settings = {
            auto_open_output = true;
            image_provider = "snacks";
          };
        };

        venv-selector.enable = true;

        neotest = {
          enable = true;
          adapters = {
            python.enable = true;
            vitest.enable = true;
            rust.enable = true;
            dotnet.enable = true;
          };
        };

        dap = {
          enable = true;

          adapters = {
            executables = {
              debugpy = {
                command = "${pythonEnv}/bin/python3";
                args = [
                  "-m"
                  "debugpy.adapter"
                ];
              };
              lldb-dap = {
                command = "${pkgs.lldb}/bin/lldb-dap";
              };
            };

            servers = {
              netcoredbg = {
                port = "\${port}";
                executable = {
                  command = "${pkgs.netcoredbg}/bin/netcoredbg";
                  args = [
                    "--interpreter=vscode"
                    "--port"
                    "\${port}"
                  ];
                };
              };
              "pwa-node" = {
                port = "\${port}";
                executable = {
                  command = "${pkgs.vscode-js-debug}/bin/js-debug";
                  args = [ "\${port}" ];
                };
              };
            };
          };

          configurations =
            let
              inputProgram = default: {
                __raw = ''
                  function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/${default}", "file")
                  end
                '';
              };
              cwd.__raw = "vim.fn.getcwd()";
              jsConfig = {
                type = "pwa-node";
                request = "launch";
                name = "Launch file";
                program = "\${file}";
                cwd = "\${workspaceFolder}";
              };
            in
            {
              python = [
                {
                  type = "debugpy";
                  request = "launch";
                  name = "Launch file";
                  program = "\${file}";
                  inherit cwd;
                }
              ];
              cs = [
                {
                  type = "netcoredbg";
                  request = "launch";
                  name = "Launch";
                  program = inputProgram "bin/Debug/";
                  inherit cwd;
                }
              ];
              rust = [
                {
                  type = "lldb-dap";
                  request = "launch";
                  name = "Launch";
                  program = inputProgram "target/debug/";
                  args = [ ];
                  inherit cwd;
                }
              ];
              javascript = [ jsConfig ];
              typescript = [ jsConfig ];
              javascriptreact = [ jsConfig ];
              typescriptreact = [ jsConfig ];
            };
        };

        dap-ui = {
          enable = true;
        };
      };

      lsp.inlayHints.enable = true;

      keymaps = [
        {
          mode = "n";
          key = "<A-c>";
          action.__raw = "function() Snacks.zen() end";
          options.desc = "Toggle zen mode";
        }
        {
          mode = "n";
          key = "<A-l>";
          action.__raw = "function() Snacks.explorer() end";
          options.desc = "Toggle explorer";
        }
        {
          mode = "n";
          key = "<A-r>";
          action.__raw = "function() Snacks.picker.lsp_symbols() end";
          options.desc = "Document symbols";
        }
        {
          mode = "n";
          key = "<A-b>";
          action.__raw = ''function() Snacks.terminal(nil, { win = { position = "bottom" } }) end'';
          options.desc = "Bottom terminal";
        }
        {
          mode = [
            "n"
            "t"
          ];
          key = "<C-`>";
          action.__raw = ''function() Snacks.terminal(vim.o.shell, { win = { position = "float" } }) end'';
          options.desc = "Floating terminal";
        }
        {
          mode = [
            "n"
            "i"
          ];
          key = "<C-k>";
          action.__raw = "vim.lsp.buf.signature_help";
          options.desc = "Signature help";
        }
        {
          mode = "n";
          key = "<A-CR>";
          action.__raw = "vim.lsp.buf.code_action";
          options.desc = "Code actions";
        }
        {
          mode = "n";
          key = "<C-]>";
          action.__raw = "vim.lsp.buf.implementation";
          options.desc = "Go to implementation";
        }
        {
          mode = "n";
          key = "\\r";
          action.__raw = "vim.lsp.buf.rename";
          options.desc = "Rename symbol";
        }
        {
          mode = "n";
          key = "gr";
          action.__raw = "vim.lsp.buf.references";
          options.desc = "References";
        }

        {
          mode = "n";
          key = "<leader>e";
          action.__raw = "function() Snacks.explorer() end";
          options.desc = "Explorer";
        }
        {
          mode = "n";
          key = "<leader>sf";
          action.__raw = "function() Snacks.picker.files() end";
          options.desc = "Find files";
        }
        {
          mode = "n";
          key = "<leader>sg";
          action.__raw = "function() Snacks.picker.grep() end";
          options.desc = "Live grep";
        }
        {
          mode = "n";
          key = "<leader>sb";
          action.__raw = "function() Snacks.picker.buffers() end";
          options.desc = "Buffers";
        }
        {
          mode = "n";
          key = "<leader>ss";
          action.__raw = "function() Snacks.picker.lsp_symbols() end";
          options.desc = "Document symbols";
        }
        {
          mode = "n";
          key = "<leader>sS";
          action.__raw = "function() Snacks.picker.lsp_workspace_symbols() end";
          options.desc = "Workspace symbols";
        }
        {
          mode = "n";
          key = "<leader>sd";
          action.__raw = "function() Snacks.picker.diagnostics() end";
          options.desc = "Diagnostics";
        }
        {
          mode = "n";
          key = "<leader>sh";
          action.__raw = "function() Snacks.picker.help() end";
          options.desc = "Help";
        }

        {
          mode = "n";
          key = "<leader>gg";
          action = "<cmd>Neogit<CR>";
          options.desc = "Git status";
        }
        {
          mode = "n";
          key = "<leader>gd";
          action = "<cmd>DiffviewOpen<CR>";
          options.desc = "Diffview";
        }
        {
          mode = "n";
          key = "]c";
          action.__raw = "function() require('gitsigns').next_hunk() end";
          options.desc = "Next git hunk";
        }
        {
          mode = "n";
          key = "[c";
          action.__raw = "function() require('gitsigns').prev_hunk() end";
          options.desc = "Previous git hunk";
        }
        {
          mode = "n";
          key = "<leader>hs";
          action.__raw = "function() require('gitsigns').stage_hunk() end";
          options.desc = "Stage hunk";
        }
        {
          mode = "n";
          key = "<leader>hr";
          action.__raw = "function() require('gitsigns').reset_hunk() end";
          options.desc = "Reset hunk";
        }
        {
          mode = "n";
          key = "<leader>hp";
          action.__raw = "function() require('gitsigns').preview_hunk() end";
          options.desc = "Preview hunk";
        }
        {
          mode = "n";
          key = "<leader>hb";
          action.__raw = "function() require('gitsigns').blame_line({ full = true }) end";
          options.desc = "Blame line";
        }

        {
          mode = "n";
          key = "<leader>oc";
          action = "<cmd>OmpCommit<CR>";
          options.desc = "omp commit";
        }

        {
          mode = "n";
          key = "<localleader>mi";
          action = "<cmd>MoltenInit<CR>";
          options.desc = "Molten init kernel";
        }
        {
          mode = "n";
          key = "<localleader>rr";
          action = "<cmd>MoltenReevaluateCell<CR>";
          options.desc = "Rerun cell";
        }
        {
          mode = "n";
          key = "<localleader>rl";
          action = "<cmd>MoltenEvaluateLine<CR>";
          options.desc = "Run line";
        }
        {
          mode = "v";
          key = "<localleader>r";
          action = "<cmd>MoltenEvaluateVisual<CR>gv";
          options.desc = "Run selection";
        }

        {
          mode = "n";
          key = "<F5>";
          action.__raw = "function() require('dap').continue() end";
          options.desc = "Debug: continue/launch";
        }
        {
          mode = "n";
          key = "<F10>";
          action.__raw = "function() require('dap').step_over() end";
          options.desc = "Debug: step over";
        }
        {
          mode = "n";
          key = "<F11>";
          action.__raw = "function() require('dap').step_into() end";
          options.desc = "Debug: step into";
        }
        {
          mode = "n";
          key = "<F12>";
          action.__raw = "function() require('dap').step_out() end";
          options.desc = "Debug: step out";
        }
        {
          mode = "n";
          key = "<leader>db";
          action.__raw = "function() require('dap').toggle_breakpoint() end";
          options.desc = "Toggle breakpoint";
        }
        {
          mode = "n";
          key = "<leader>du";
          action.__raw = "function() require('dapui').toggle() end";
          options.desc = "Toggle debug UI";
        }

        {
          mode = "n";
          key = "<leader>tt";
          action.__raw = "function() require('neotest').run.run() end";
          options.desc = "Run nearest test";
        }
        {
          mode = "n";
          key = "<leader>tf";
          action.__raw = "function() require('neotest').run.run(vim.fn.expand('%')) end";
          options.desc = "Run file tests";
        }
        {
          mode = "n";
          key = "<leader>ts";
          action.__raw = "function() require('neotest').summary.toggle() end";
          options.desc = "Toggle test summary";
        }
        {
          mode = "n";
          key = "<leader>to";
          action.__raw = "function() require('neotest').output.open({ enter = true }) end";
          options.desc = "Open test output";
        }
      ];
    };
  };
}
