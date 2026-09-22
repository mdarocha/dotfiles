{
  pkgs,
  pythonEnv,
  bottomTerminal,
}:
{
  plugins = {
    gitsigns.enable = true;
    fugitive.enable = true;
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
      action.__raw = "function() require('nvim-tree.api').tree.toggle() end";
      options.desc = "Toggle file explorer";
    }
    {
      mode = "n";
      key = "<A-r>";
      action.__raw = "function() require('aerial').toggle() end";
      options.desc = "Toggle outline";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<A-b>";
      action.__raw = bottomTerminal;
      options.desc = "Bottom terminal";
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<C-`>";
      action.__raw = bottomTerminal;
      options.desc = "Bottom terminal";
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
      key = "gd";
      action.__raw = "vim.lsp.buf.definition";
      options.desc = "Go to definition";
    }
    {
      mode = "n";
      key = "g/";
      action.__raw = "function() Snacks.picker.grep() end";
      options.desc = "Search all files";
    }
    {
      mode = "n";
      key = "<C-PageDown>";
      action = "<cmd>BufferLineCycleNext<CR>";
      options.desc = "Next tab";
    }
    {
      mode = "n";
      key = "<C-PageUp>";
      action = "<cmd>BufferLineCyclePrev<CR>";
      options.desc = "Previous tab";
    }
    {
      mode = "n";
      key = "<C-Tab>";
      action = "<cmd>BufferLineCycleNext<CR>";
      options.desc = "Next tab";
    }
    {
      mode = "n";
      key = "<C-S-Tab>";
      action = "<cmd>BufferLineCyclePrev<CR>";
      options.desc = "Previous tab";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<CR>";
      options.desc = "Close buffer";
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>BufferLinePick<CR>";
      options.desc = "Pick buffer";
    }

    {
      mode = "n";
      key = "<leader>e";
      action.__raw = "function() require('nvim-tree.api').tree.focus() end";
      options.desc = "Focus file explorer";
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
      action.__raw = "function() require('aerial').open({ focus = true }) end";
      options.desc = "Focus outline";
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
      action = "<cmd>Git<CR>";
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
}
