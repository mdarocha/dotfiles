# neovim

Home Manager module that configures a full Neovim workbench with
[nixvim](https://github.com/nix-community/nixvim), replacing the previous Zed
setup. Every plugin, language server, and debug adapter is installed
declaratively through Nix — there is no runtime plugin manager, no Mason, and
nothing is downloaded on first launch. Enable it with
`mdarocha.neovim.enable = true;`.

`<leader>` is `Space`, `<localleader>` is `,` (Neovim defaults).

## Layout

- `default.nix` — the Home Manager module: options, packages, plugin enables,
  language servers, DAP adapters/configurations, and keymaps.
- `lua/options.lua` — core `vim.opt` settings, per-filetype indent width, and
  the autosave-on-focus-lost autocommand.
- `lua/ui.lua` — activates the Solarized colorscheme.
- `lua/lsp.lua` — format-on-save, [roslyn.nvim](https://github.com/seblyng/roslyn.nvim)
  setup, `vtsls` convenience commands, and the venv-selector → Pyright restart hook.
- `lua/workbench.lua` — [jupytext.nvim](https://github.com/GCBallesteros/jupytext.nvim) setup.
- `lua/keymaps.lua` — the `:OmpCommit` user command.

## Editor & UI

- **Colorscheme**: [solarized.nvim](https://github.com/maxmx03/solarized.nvim),
  dark background (`:set background=light` switches to the light variant).
- **[snacks.nvim](https://github.com/folke/snacks.nvim)** is the single UI
  framework for file explorer, fuzzy pickers, floating/persistent terminals,
  in-terminal image rendering (Kitty Graphics Protocol), notifications, indent
  guides, and the statuscolumn.
  - `<leader>e` / `<A-l>` — toggle the file explorer
  - `<leader>sf` — find files, `<leader>sg` — live grep, `<leader>sb` — buffers
  - `<leader>ss` — document symbols, `<leader>sS` — workspace symbols
  - `<leader>sd` — diagnostics, `<leader>sh` — help tags
  - `<A-b>` — bottom terminal, `` <C-`> `` — floating terminal
  - `<A-c>` — zen mode (centered layout)
- **[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)** — statusline
  (mode, branch, diagnostics, filetype, position), Solarized theme.
- **[which-key.nvim](https://github.com/folke/which-key.nvim)** — shows
  available bindings under `<leader>s`/`g`/`h`/`d`/`t`/`o` after a short pause.
- **[auto-session](https://github.com/rmagatti/auto-session)** — restores the
  last session per working directory on startup.
- **[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)** —
  in-buffer Markdown rendering (headings, tables, checkboxes, code blocks);
  linked images render through `snacks.image` when the terminal supports the
  Kitty Graphics Protocol.

## Language intelligence

Configured through Neovim's built-in `vim.lsp.config`/`vim.lsp.enable` API via
nixvim's `plugins.lsp.servers.*`, with [blink.cmp](https://github.com/Saghen/blink.cmp)
supplying LSP/buffer/path/snippet completion and inlay hints enabled globally.
Buffers format on save (`vim.lsp.buf.format`) only when the attached server
supports it — no external formatter is ever invoked.

| Language          | Server                                                        | Notes |
| ------------------ | -------------------------------------------------------------- | ----- |
| Nix                | [`nil`](https://github.com/oxalica/nil)                         | `nix.flake.autoArchive = false` |
| Lua                | [`lua-language-server`](https://github.com/LuaLS/lua-language-server) | |
| Python             | [`pyright`](https://github.com/microsoft/pyright)               | paired with `venv-selector.nvim` |
| Rust               | [`rust-analyzer`](https://rust-analyzer.github.io)              | toolchain (`cargo`/`rustc`/`rustfmt`) provided by Nix |
| C# / .NET          | [`roslyn-ls`](https://github.com/dotnet/roslyn) via [roslyn.nvim](https://github.com/seblyng/roslyn.nvim) | solution/project discovery, `:Roslyn target` |
| TypeScript/JS/TSX  | [`vtsls`](https://github.com/yioneko/vtsls)                     | `updateImportsOnFileMove = "always"`; `:VtsOrganizeImports`, `:VtsSourceDefinition` |
| HTML/CSS/JSON      | [`vscode-langservers-extracted`](https://github.com/hrsh7th/vscode-langservers-extracted) | |
| YAML               | [`yaml-language-server`](https://github.com/redhat-developer/yaml-language-server) | |
| XML (incl. `.csproj`/`.fsproj`/`.props`) | [`lemminx`](https://github.com/eclipse/lemminx) | |
| Zig                | [`zls`](https://github.com/zigtools/zls)                        | |

**[venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim)**
finds and selects a project's Python virtual environment; selecting one
restarts Pyright with the new interpreter.

## Python notebooks

- **[molten-nvim](https://github.com/benlubas/molten-nvim)** runs code against
  a live Jupyter kernel and renders rich output (including plots) through
  `snacks.image`. Works on `# %%`-delimited Python cells and fenced code
  blocks in Markdown.
  - `<localleader>mi` — init/select a kernel
  - `<localleader>rr` — re-run the current cell
  - `<localleader>rl` — run the current line
  - `<localleader>r` (visual) — run the selection
- **[jupytext.nvim](https://github.com/GCBallesteros/jupytext.nvim)** transparently
  opens `.ipynb` files as paired `# %%` Python scripts (via the `jupytext` CLI)
  and writes them back as notebooks on save. Molten owns kernel state and output;
  jupytext only owns the text representation.

## Debugging (nvim-dap)

[nvim-dap](https://github.com/mfussenegger/nvim-dap) +
[nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui), with adapters resolved
from Nix store paths (no downloads, no Mason):

| Language   | Adapter | Package |
| ---------- | ------- | ------- |
| Python     | `debugpy` | `python3.withPackages` env with `debugpy` |
| C#/.NET    | `netcoredbg` | [`netcoredbg`](https://github.com/Samsung/netcoredbg) |
| JS/TS      | `vscode-js-debug` (`pwa-node`) | [`vscode-js-debug`](https://github.com/microsoft/vscode-js-debug) |
| Rust       | `lldb-dap` | `lldb` |

On launch you're prompted for the program path (or file/cwd defaults);
`cwd` defaults to the project root.

- `F5` — continue/launch, `F10` — step over, `F11` — step into, `F12` — step out
- `<leader>db` — toggle breakpoint, `<leader>du` — toggle the debug UI

## Testing ([neotest](https://github.com/nvim-neotest/neotest))

Native adapters for Python ([neotest-python](https://github.com/nvim-neotest/neotest-python)),
JS/TS ([neotest-vitest](https://github.com/marilari88/neotest-vitest)), Rust
([neotest-rust](https://github.com/rouge8/neotest-rust)), and C#/.NET
([neotest-dotnet](https://github.com/Issafalcon/neotest-dotnet)) share the same
keymaps:

- `<leader>tt` — run the nearest test
- `<leader>tf` — run all tests in the current file
- `<leader>ts` — toggle the test summary panel
- `<leader>to` — open the last test's output

## Git

- **[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)** — gutter
  signs, hunk staging/reset/preview, line blame: `]c`/`[c` navigate hunks,
  `<leader>hs`/`hr`/`hp` stage/reset/preview, `<leader>hb` blames the line.
- **[neogit](https://github.com/NeoGitOrg/neogit)** (`<leader>gg`) — status,
  staging, committing, branches, log.
- **[diffview.nvim](https://github.com/sindrets/diffview.nvim)** (`<leader>gd`) —
  diff review, file history, merge conflicts.
- **`:OmpCommit`** (`<leader>oc`) — runs `omp commit` in a Snacks terminal at
  the repository root; no-ops with a notification outside a Git worktree or
  if `omp` isn't on `PATH`.

## Copilot

[copilot.lua](https://github.com/zbirenbaum/copilot.lua) provides inline
suggestions only (no chat panel — that's out of scope for this workbench).
Authenticate once with `:Copilot auth`. `<C-y>` accepts a suggestion; `Tab`
keeps its normal completion/indent behavior.

## Treesitter

Grammars for `bash`, `c_sharp`, `css`, `html`, `javascript`, `json`, `jsonc`,
`lua`, `markdown`, `markdown_inline`, `nix`, `python`, `rust`, `tsx`,
`typescript`, `vim`, `vimdoc`, `xml`, `yaml`, and `zig` are installed via Nix
(`plugins.treesitter.grammarPackages`) — no runtime `:TSInstall` required.

## Verifying a checkout

```
nvim --headless '+checkhealth' '+qa'
```

reports the status of every plugin above, including whether each declared LSP
server/DAP adapter binary is reachable.
