# Debugging: nvim-dap and nvim-dap-ui with Nix-packaged adapters for Python, .NET, JS/TS, and Rust.
{ pkgs, pythonEnv, ... }:
{
  plugins = {
    # Nix supplies adapters; launch configurations prompt for project binaries.
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

  # Adapters also on PATH for tools that look them up by name; lldb provides lldb-dap.
  extraPackagesAfter = with pkgs; [
    netcoredbg
    vscode-js-debug
    lldb
  ];

  keymaps = [
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
  ];
}
