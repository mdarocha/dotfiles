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

[nvim-tree.nvim](https://github.com/nvim-tree/nvim-tree.lua) is a persistent
36-column explorer on the left. [Aerial](https://github.com/stevearc/aerial.nvim)
is the document-symbol outline on the right.
[snacks.nvim](https://github.com/folke/snacks.nvim) provides pickers, the bottom
terminal, notifications, indent guides, status column, images, and Zen mode.
[mini.clue](https://github.com/echasnovski/mini.nvim) shows compact leader hints
in the lower-right corner. [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
shows the active Python environment and attached LSP server count; click the count
for a brief server-list notification. [fidget.nvim](https://github.com/j-hui/fidget.nvim)
displays server progress and messages in floating notifications.

`vim`, `$EDITOR`, and `$VISUAL` resolve to this configured Neovim. Line numbers
are absolute in Normal mode and relative in other editing modes.

### Explorer

| Key | Action |
| --- | --- |
| `<leader>e` | Focus or open the left explorer |
| `<A-l>` | Toggle the left explorer |
| `o` or `l` | Open the selected file or directory |
| `h` | Close the current directory or move to its parent |
| `I` | Show or hide Git-ignored files |
| `H` | Show or hide dotfiles |

Git-ignored files are hidden by default; press `I` while the explorer is
focused to show them. Dotfiles are visible by default. Diagnostics appear
beside affected files, not in a separate gutter or on every parent directory.

| Key | Action |
| --- | --- |
| `<A-r>` | Toggle the right document-symbol outline |
| `<leader>ss` | Focus or open the right document-symbol outline |
| `<A-b>` or ``<C-`>`` | Toggle the bottom terminal |
| `<A-c>` | Toggle the centered editing layout |
| `g/` | Search across the project |
| `<leader>sf` | Find files |
| `<leader>sg` | Search file contents |
| `<leader>sb` | List buffers |
| `<leader>sS` | Find workspace symbols |
| `<leader>sd` | List diagnostics |
| `<leader>sh` | Search help |

Terminals always open in a bottom split.

### Tabs

Every open file buffer appears in the tab bar; utility panes stay out of it. Click
a buffer to focus it or its close icon to close it. `gt` and `gT` cycle the
displayed buffers. `:bnext` and `:bprevious` also work.

| Key | Action |
| --- | --- |
| `gt` / `gT` | Next / previous buffer tab |
| `<leader>bp` | Jump to a buffer by its letter |
| `<leader>bd` | Close the current buffer |

### Splits

Splits use Vim's `<C-w>` window commands.

| Key | Action |
| --- | --- |
| `<C-w>v` | Split vertically |
| `<C-w>s` | Split horizontally |
| `<C-w>h/j/k/l` | Move to the split left/below/above/right |
| `<C-w>H/J/K/L` | Move the current split to that edge |
| `<C-w>=` | Equalize split sizes |
| `<C-w>_` or `<C-w>|` | Maximize height or width |
| `<C-w>c` | Close the current split |
| `<C-w>o` | Close every other split |

New splits open to the right and below.

[Solarized Osaka](https://github.com/craftzdog/solarized-osaka.nvim) starts in dark
mode with Ghostty's `#002b36` canvas and `#073642` panels.
`:colorscheme solarized-osaka-light` selects its light variant.

`snacks.image` displays linked images and math in terminals that support the
Kitty Graphics Protocol; the source stays visible elsewhere.

## Language support

Neovim's built-in `vim.lsp.config` and `vim.lsp.enable` APIs manage the
servers. nixvim uses [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
for maintained server definitions. [blink.cmp](https://github.com/Saghen/blink.cmp)
adds LSP, buffer, path, and snippet completion.

| Language | Server | Details |
| --- | --- | --- |
| Nix | [`nil`](https://github.com/oxalica/nil) | Automatic flake archiving is disabled |
| Lua | [`lua-language-server`](https://github.com/LuaLS/lua-language-server) | [lazydev.nvim](https://github.com/folke/lazydev.nvim) supplies Neovim and plugin runtime types |
| Python | [`pyright`](https://github.com/microsoft/pyright) | Virtual environments are selected with [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) |
| Rust | [`rust-analyzer`](https://rust-analyzer.github.io) | Nix also provides `cargo`, `rustc`, and `rustfmt` |
| C# and Razor | [`roslyn-ls`](https://github.com/dotnet/roslyn) with [roslyn.nvim](https://github.com/seblyng/roslyn.nvim) | Discovers solutions and projects; `:Roslyn target` switches targets |
| JavaScript, TypeScript, JSX, TSX | [`vtsls`](https://github.com/yioneko/vtsls) | File renames update import paths; `:VtsOrganizeImports` and `:VtsSourceDefinition` are available |
| HTML, CSS, JSON | [`vscode-langservers-extracted`](https://github.com/hrsh7th/vscode-langservers-extracted) | Schemas come from [SchemaStore.nvim](https://github.com/b0o/SchemaStore.nvim) |
| YAML | [`yaml-language-server`](https://github.com/redhat-developer/yaml-language-server) | Schemas come from [SchemaStore.nvim](https://github.com/b0o/SchemaStore.nvim) |
| XML, `.csproj`, `.fsproj`, `.props` | [`lemminx`](https://github.com/eclipse/lemminx) | |
| Zig | [`zls`](https://github.com/zigtools/zls) | |

Formatting uses the capabilities advertised by the attached server. Inlay hints
are disabled.

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | List references |
| `<C-]>` | Go to implementation |
| `K` or `<C-k>` in Normal mode | Show diagnostics on the current line, otherwise hover documentation |
| `<C-k>` in Insert mode | Show signature help |
| `<A-CR>` | Show code actions |
| `\r` | Rename the symbol under the cursor |

`gr` shares a prefix with Neovim's built-in `grn`, `gra`, `gri`, and `grr`
mappings, so it waits for `timeoutlen` before listing references. Those
built-ins still work.

[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) grammars
are compiled by Nix for Bash, C#, CSS, HTML, JavaScript, JSON, Lua, Markdown,
Nix, Python, Rust, TSX, TypeScript, Vim, XML, YAML, and Zig. They ship as store
paths on the runtimepath, so startup loads them without compiling or
downloading anything.

`.json`, `.yaml`, and `.yml` files get completion, validation, and hover
documentation from the [SchemaStore](https://www.schemastore.org) catalog,
which is also installed as a Nix package.

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

[vim-fugitive](https://github.com/tpope/vim-fugitive) owns `:Git`; `<leader>gg`
opens its Git status window. [diffview.nvim](https://github.com/sindrets/diffview.nvim)
opens reviews, file history, and merge conflicts with `<leader>gd`.

`:OmpCommit` and `<leader>oc` run `omp commit` in a terminal rooted at the
current Git repository. Outside a Git repository, the command displays a
notification and stops.

[copilot.lua](https://github.com/zbirenbaum/copilot.lua) provides inline
suggestions. Run `:Copilot auth` once to authenticate. `<C-y>` accepts a
suggestion; `Tab` keeps its normal completion and indentation behavior.

## Files

- `default.nix` assembles the Neovim module.
- `modules/core.nix` configures the runtime, packages, editor aliases, and
  shared Lua setup.
- `modules/editor.nix` configures syntax, completion, schemas, and language
  servers.
- `modules/interface.nix` configures panes, statusline, tabs, hints, and visual
  presentation.
- `modules/workflow.nix` configures Git, notebooks, Copilot, debugging, tests,
  and keymaps.
- `lua/options.lua` contains editor options, filetype indentation, and
  autosave-on-focus-change.
- `lua/ui.lua` loads Solarized Osaka without local highlight overrides.
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
