# Neovim

Neovim configured with [nixvim](https://github.com/nix-community/nixvim). Nix
provides the plugins, language servers, debug adapters, and every external tool
they call.

- Enable: `mdarocha.neovim.enable = true;`
- `<leader>` is `\`, `<localleader>` is `,`. `<leader>gg` means `\gg`.
- `vim`, `$EDITOR`, and `$VISUAL` open this Neovim.

## Run and check

| Command | Does |
| --- | --- |
| `nix run .#neovim` | Run the `nixos` profile's Neovim without activating Home Manager |
| `nix run .#neovim -- .` | Same, with Neovim arguments after `--` |
| `nvim --headless '+checkhealth' '+qa'` | Health check after activation |
| `nix run .#neovim -- --headless '+checkhealth' '+qa'` | Health check of the standalone app |
| `nix build .#checks.x86_64-linux.neovim` | Start Neovim in the build sandbox; fails on startup errors or nixvim warnings |

## Layout

`default.nix` declares the Home Manager option, builds the shared Python
environment, and imports one nixvim module per directory. Each module owns its
plugins, external tools, keymaps, and Lua.

| Directory | Configures |
| --- | --- |
| `core/` | Aliases, leader keys, Python provider, clipboard, editor options, autosave |
| `theme/` | Solarized Osaka, highlight overrides, file icons, float borders |
| `snacks/` | [snacks.nvim](https://github.com/folke/snacks.nvim): pickers, terminal, notifications, images, Zen mode |
| `filetree/` | [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) explorer (left) |
| `outline/` | [Aerial](https://github.com/stevearc/aerial.nvim) symbol outline (right) |
| `tabs/` | [bufferline](https://github.com/akinsho/bufferline.nvim) buffer tabs and `gt`/`gT` cycling |
| `statusline/` | [lualine](https://github.com/nvim-lualine/lualine.nvim) |
| `hints/` | [mini.clue](https://github.com/echasnovski/mini.nvim) `<leader>` hints |
| `session/` | [auto-session](https://github.com/rmagatti/auto-session) |
| `treesitter/` | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with Nix-built grammars |
| `completion/` | [blink.cmp](https://github.com/Saghen/blink.cmp) |
| `lsp/` | Language servers, LSP keymaps, [fidget](https://github.com/j-hui/fidget.nvim), [venv-selector](https://github.com/linux-cultist/venv-selector.nvim) |
| `copilot/` | [copilot.lua](https://github.com/zbirenbaum/copilot.lua) |
| `git/` | [Fugitive](https://github.com/tpope/vim-fugitive), [Gitsigns](https://github.com/lewis6991/gitsigns.nvim), [Diffview](https://github.com/sindrets/diffview.nvim), `:OmpCommit` |
| `notebook/` | [Molten](https://github.com/benlubas/molten-nvim) and [Jupytext](https://github.com/GCBallesteros/jupytext.nvim) |
| `debug/` | [nvim-dap](https://github.com/mfussenegger/nvim-dap) and [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) |
| `test/` | [neotest](https://github.com/nvim-neotest/neotest) |

snacks.nvim, lualine, Diffview, and Jupytext are patched at build time to drop
deprecated Neovim API calls; each patch lives in the module that uses the
plugin and links its upstream issue.

## Keymaps

### Files and search

| Key | Action |
| --- | --- |
| `<C-p>`, `<leader>sf` | Find files |
| `g/`, `<leader>sg` | Search file contents |
| `<leader>sb` | List buffers |
| `<leader>sS` | Workspace symbols |
| `<leader>sd` | Diagnostics |
| `<leader>sh` | Help |

### Panes

| Key | Action |
| --- | --- |
| `<leader>e` | Focus or open the explorer |
| `<A-l>` | Toggle the explorer |
| `<leader>ss` | Focus or open the outline |
| `<A-r>` | Toggle the outline |
| `<A-b>`, ``<C-`>`` | Toggle the bottom terminal |
| `<A-c>` | Toggle Zen mode (centered layout) |

Inside the explorer:

| Key | Action |
| --- | --- |
| `o`, `l` | Open file or directory |
| `h` | Close directory or go to parent |
| `I` | Toggle Git-ignored files (hidden by default) |
| `H` | Toggle dotfiles (shown by default) |

Diagnostics show beside the affected file, not on its parent directories.

### Buffer tabs and splits

| Key | Action |
| --- | --- |
| `gt` / `gT` | Next / previous buffer tab, from any window |
| `<leader>bp` | Jump to a buffer by its letter |
| `<leader>bd` | Close the current buffer |
| `<C-w>v` / `<C-w>s` | Split vertically / horizontally |
| `<C-w>h/j/k/l` | Move to the split left / below / above / right |
| `<C-w>H/J/K/L` | Move the split to that edge |
| `<C-w>=` | Equalize split sizes |
| `<C-w>_`, `<C-w>\|` | Maximize height / width |
| `<C-w>c` / `<C-w>o` | Close this split / all other splits |

The tab bar shows open file buffers only. Click a tab to focus it; click its
icon, or right/middle-click it, to close it. When `gt` starts from the
explorer, outline, terminal, help, or quickfix, it jumps to a file window first.
New splits open right and below.

### Code

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | List references (waits `timeoutlen`: shares a prefix with `grn`, `gra`, `gri`, `grr`) |
| `<C-]>` | Go to implementation |
| `K`, `<C-k>` | Diagnostics on the current line, otherwise hover documentation |
| `<C-k>` (Insert) | Signature help |
| `<A-CR>` | Code actions |
| `<leader>r` | Rename symbol |

### Completion and Copilot

| Key | Action |
| --- | --- |
| `<Tab>` | Accept the completion entry; without a menu, next snippet field or indent |
| `<Up>` / `<Down>` | Move in the completion menu; otherwise the usual cursor movement |
| `<C-y>` (Insert) | Accept the Copilot suggestion, even over the completion menu; otherwise Vim's default |
| `<C-]>` (Insert) | Dismiss the Copilot suggestion |

### Git

| Key | Action |
| --- | --- |
| `<leader>gg` | Fugitive status |
| `<leader>gd` | Diffview (review, history, merge conflicts) |
| `]c` / `[c` | Next / previous hunk |
| `<leader>hs` / `<leader>hr` | Stage / reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| `<leader>oc` | `:OmpCommit` |

### Debugging

| Key | Action |
| --- | --- |
| `<F5>` | Launch or continue |
| `<F10>` / `<F11>` / `<F12>` | Step over / into / out |
| `<leader>db` | Toggle breakpoint |
| `<leader>du` | Toggle the debug UI |

### Tests

| Key | Action |
| --- | --- |
| `<leader>tt` | Run the nearest test |
| `<leader>tf` | Run the current file's tests |
| `<leader>ts` | Toggle the test summary |
| `<leader>to` | Open the last test output |

### Notebooks

| Key | Action |
| --- | --- |
| `<localleader>mi` | Select or start a kernel |
| `<localleader>rr` | Rerun the current cell |
| `<localleader>rl` | Run the current line |
| `<localleader>r` (Visual) | Run the selection |

## Commands

| Command | Does |
| --- | --- |
| `:OmpCommit` | Run `omp commit` in a bottom terminal at the file's Git root |
| `:Git` | Fugitive |
| `:Copilot auth` | Authenticate Copilot (once) |
| `:Roslyn target` | Switch the C# solution or project |
| `:VtsOrganizeImports` | Organize TypeScript/JavaScript imports |
| `:VtsSourceDefinition` | Go to the source definition instead of the `.d.ts` |
| `:VenvSelect` | Pick a Python virtual environment; Pyright restarts to use it |
| `:colorscheme solarized-osaka-light` | Light theme |

## Languages

Servers run on Neovim's built-in LSP client (`vim.lsp.config`/`vim.lsp.enable`)
with definitions from [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
Formatting uses whatever the attached server supports. Inlay hints are off.

| Language | Server | Debug adapter | Test adapter |
| --- | --- | --- | --- |
| Nix | [`nil`](https://github.com/oxalica/nil), flake auto-archiving off | | |
| Lua | [`lua-language-server`](https://github.com/LuaLS/lua-language-server) + [lazydev](https://github.com/folke/lazydev.nvim) for Neovim types | | |
| Python | [`pyright`](https://github.com/microsoft/pyright) | [`debugpy`](https://github.com/microsoft/debugpy) | [neotest-python](https://github.com/nvim-neotest/neotest-python) |
| Rust | [`rust-analyzer`](https://rust-analyzer.github.io) (`cargo`, `rustc`, `rustfmt` on PATH) | `lldb-dap` from [LLVM](https://lldb.llvm.org) | [neotest-rust](https://github.com/rouge8/neotest-rust) |
| C#, Razor | [`roslyn-ls`](https://github.com/dotnet/roslyn) via [roslyn.nvim](https://github.com/seblyng/roslyn.nvim) | [`netcoredbg`](https://github.com/Samsung/netcoredbg) | [neotest-dotnet](https://github.com/Issafalcon/neotest-dotnet) |
| JS, TS, JSX, TSX | [`vtsls`](https://github.com/yioneko/vtsls), imports follow file renames | [`vscode-js-debug`](https://github.com/microsoft/vscode-js-debug) (`pwa-node`) | [neotest-vitest](https://github.com/marilari88/neotest-vitest) |
| HTML, CSS, JSON | [`vscode-langservers-extracted`](https://github.com/hrsh7th/vscode-langservers-extracted) | | |
| YAML | [`yaml-language-server`](https://github.com/redhat-developer/yaml-language-server) | | |
| XML, `.csproj`, `.fsproj`, `.props` | [`lemminx`](https://github.com/eclipse/lemminx) | | |
| Zig | [`zls`](https://github.com/zigtools/zls) | | |

- JSON and YAML get completion, validation, and hover from the
  [SchemaStore](https://www.schemastore.org) catalog via
  [SchemaStore.nvim](https://github.com/b0o/SchemaStore.nvim).
- Treesitter grammars are built by Nix and loaded from the store; nothing is
  compiled or downloaded at startup.
- Debug launches for C# and Rust prompt for the executable, starting from
  `bin/Debug/` and `target/debug/`.

## Behavior

| Topic | Behavior |
| --- | --- |
| Line numbers | Absolute in Normal mode, relative in other modes |
| Clipboard | System clipboard: `wl-copy`/`wl-paste` on Wayland, `clip.exe` and PowerShell on WSL |
| Autosave | Modified named files are written on focus loss or buffer leave |
| Indentation | 4 spaces; 2 for JSON, YAML, XML, Nix, and Lua |
| Sessions | Saved per working directory and restored on start, falling back to the most recent; sidebars, terminals, and pickers are left out |
| Terminals | Always a bottom split |
| Status line | Active Python environment and attached LSP server count; click the count to list servers |
| Key hints | mini.clue lists `<leader>` continuations in the lower-right corner |
| Notifications | LSP progress and server messages appear in fidget popups |
| Theme | [Solarized Osaka](https://github.com/craftzdog/solarized-osaka.nvim) dark on Ghostty's `#002b36` canvas with `#073642` panels |
| Images | `snacks.image` renders images, math, PDFs, and Mermaid in Kitty-graphics terminals; other terminals show the source |
| Notebooks | `.ipynb` opens as a Python buffer with `# %%` cells and saves back to the notebook; Molten keeps kernel state and shows output inline |
