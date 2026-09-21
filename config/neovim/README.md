# Neovim

Enable the Home Manager module with `mdarocha.neovim.enable = true`.
[nixvim](https://github.com/nix-community/nixvim) packages Neovim, its plugins,
language servers, debug adapters, and supporting tools.

`<leader>` is `\` and `<localleader>` is `,`. For example, `<leader>gg`
means `\gg`.

## Run without activating Home Manager

From the repository root:

```sh
nix run .#neovim
```

Pass Neovim arguments after `--`:

```sh
nix run .#neovim -- .
```

This runs the generated `nixos` profile configuration directly from the Nix
store.

## Everyday editing

[snacks.nvim](https://github.com/folke/snacks.nvim) handles the explorer,
pickers, terminals, notifications, indent guides, status column, and inline
images. [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) displays
the status line. [which-key.nvim](https://github.com/folke/which-key.nvim)
lists leader mappings, and [auto-session](https://github.com/rmagatti/auto-session)
restores the session for the current directory.

| Key | Action |
| --- | --- |
| `<leader>e` or `<A-l>` | Open the file explorer |
| `<leader>sf` | Find files |
| `<leader>sg` | Search file contents |
| `<leader>sb` | List buffers |
| `<leader>ss` | Find document symbols |
| `<leader>sS` | Find workspace symbols |
| `<leader>sd` | List diagnostics |
| `<leader>sh` | Search help |
| `<A-b>` | Toggle a bottom terminal |
| ``<C-`>`` | Toggle a floating terminal |
| `<A-c>` | Toggle the centered editing layout |

[solarized.nvim](https://github.com/maxmx03/solarized.nvim) starts in dark
mode. `:set background=light` switches to its light palette.

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
renders headings, tables, checkboxes, callouts, and code blocks. `snacks.image`
displays linked images and math in terminals that support the Kitty Graphics
Protocol; the source stays visible elsewhere.

## Language support

Neovim's built-in `vim.lsp.config` and `vim.lsp.enable` APIs manage the
servers. nixvim uses [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
for maintained server definitions. [blink.cmp](https://github.com/Saghen/blink.cmp)
adds LSP, buffer, path, and snippet completion.

| Language | Server | Details |
| --- | --- | --- |
| Nix | [`nil`](https://github.com/oxalica/nil) | Automatic flake archiving is disabled |
| Lua | [`lua-language-server`](https://github.com/LuaLS/lua-language-server) | Neovim runtime files are available to the server |
| Python | [`pyright`](https://github.com/microsoft/pyright) | Virtual environments are selected with [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) |
| Rust | [`rust-analyzer`](https://rust-analyzer.github.io) | Nix also provides `cargo`, `rustc`, and `rustfmt` |
| C# and Razor | [`roslyn-ls`](https://github.com/dotnet/roslyn) with [roslyn.nvim](https://github.com/seblyng/roslyn.nvim) | Discovers solutions and projects; `:Roslyn target` switches targets |
| JavaScript, TypeScript, JSX, TSX | [`vtsls`](https://github.com/yioneko/vtsls) | File renames update import paths; `:VtsOrganizeImports` and `:VtsSourceDefinition` are available |
| HTML, CSS, JSON | [`vscode-langservers-extracted`](https://github.com/hrsh7th/vscode-langservers-extracted) | |
| YAML | [`yaml-language-server`](https://github.com/redhat-developer/yaml-language-server) | |
| XML, `.csproj`, `.fsproj`, `.props` | [`lemminx`](https://github.com/eclipse/lemminx) | |
| Zig | [`zls`](https://github.com/zigtools/zls) | |

Formatting and inlay hints use the capabilities advertised by the attached
server.

[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) grammars
are installed through Nix for Bash, C#, CSS, HTML, JavaScript, JSON, Lua,
Markdown, Nix, Python, Rust, TSX, TypeScript, Vim, XML, YAML, and Zig.

## Python notebooks

[molten-nvim](https://github.com/benlubas/molten-nvim) runs Python cells and
Markdown code blocks in a Jupyter kernel. Text output appears in Neovim;
plots use `snacks.image` when the terminal can display them.

| Key | Action |
| --- | --- |
| `<localleader>mi` | Select or initialize a kernel |
| `<localleader>rr` | Run the current cell again |
| `<localleader>rl` | Run the current line |
| `<localleader>r` in visual mode | Run the selection |

[jupytext.nvim](https://github.com/GCBallesteros/jupytext.nvim) opens `.ipynb`
files as Python buffers with `# %%` cell markers and writes changes back to the
notebook. Molten keeps the kernel state and output; Jupytext handles the text
representation.

## Debugging and tests

[nvim-dap](https://github.com/mfussenegger/nvim-dap) and
[nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) configure these Nix
packaged adapters:

| Language | Adapter |
| --- | --- |
| Python | [`debugpy`](https://github.com/microsoft/debugpy) |
| C# and .NET | [`netcoredbg`](https://github.com/Samsung/netcoredbg) |
| JavaScript and TypeScript | [`vscode-js-debug`](https://github.com/microsoft/vscode-js-debug) (`pwa-node`) |
| Rust | `lldb-dap` from [LLVM](https://lldb.llvm.org) |

| Key | Action |
| --- | --- |
| `F5` | Launch or continue |
| `F10` | Step over |
| `F11` | Step into |
| `F12` | Step out |
| `<leader>db` | Toggle a breakpoint |
| `<leader>du` | Toggle the debug UI |

[neotest](https://github.com/nvim-neotest/neotest) runs tests through
[neotest-python](https://github.com/nvim-neotest/neotest-python),
[neotest-vitest](https://github.com/marilari88/neotest-vitest),
[neotest-rust](https://github.com/rouge8/neotest-rust), and
[neotest-dotnet](https://github.com/Issafalcon/neotest-dotnet).

| Key | Action |
| --- | --- |
| `<leader>tt` | Run the nearest test |
| `<leader>tf` | Run tests in the current file |
| `<leader>ts` | Toggle the test summary |
| `<leader>to` | Open the last test output |

## Git and Copilot

[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) adds gutter signs
and hunk operations. `]c` and `[c` move between hunks. `<leader>hs`,
`<leader>hr`, `<leader>hp`, and `<leader>hb` stage, reset, preview, and blame.

[neogit](https://github.com/NeogitOrg/neogit) opens repository status with
`<leader>gg`. [diffview.nvim](https://github.com/sindrets/diffview.nvim) opens
reviews, file history, and merge conflicts with `<leader>gd`.

`:OmpCommit` and `<leader>oc` run `omp commit` in a terminal rooted at the
current Git repository. Outside a Git repository, the command displays a
notification and stops.

[copilot.lua](https://github.com/zbirenbaum/copilot.lua) provides inline
suggestions. Run `:Copilot auth` once to authenticate. `<C-y>` accepts a
suggestion; `Tab` keeps its normal completion and indentation behavior.

## Files

- `default.nix` declares packages, plugins, language servers, debug adapters,
  and keymaps.
- `lua/options.lua` contains editor options, filetype indentation, and
  autosave-on-focus-change.
- `lua/ui.lua` loads Solarized.
- `lua/lsp.lua` contains format-on-save, Roslyn startup, vtsls commands, and
  the Pyright restart after a virtual-environment change.
- `lua/workbench.lua` configures Jupytext.
- `lua/keymaps.lua` defines `:OmpCommit`.

## Check the installation

After activation, run:

```sh
nvim --headless '+checkhealth' '+qa'
```

For the standalone app:

```sh
nix run .#neovim -- --headless '+checkhealth' '+qa'
```
