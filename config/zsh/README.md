# zsh

Home Manager module for zsh, `direnv`, and a nix-index-backed `command-not-found`.
Below are the parts that differ from a stock zsh/Home Manager setup and how to
use them — see `default.nix` for the rest (aliases, packages, plugin list).

## Prompt: blockline

`blockline.plugin.zsh` is a small custom prompt. Left to right, in
Solarized-colored blocks: SSH/Codespaces host, active `nix shell`/`direnv`
context, active Python venv, the last three path components, background job
count, and git branch + status (staged `+`, modified `!`, untracked `.`,
ahead/behind counts). There's no option for it; edit the file directly to
change segments.

## Window title

`zsh-windows-title` sets the terminal window title to the current directory
and the last command run — nothing to enable, it's always on.

## Interactive editing

Turned on beyond Home Manager's own zsh defaults:

- Autosuggestion — ghost-text completion from history as you type; accept
  with → or `End`.
- History substring search — type a prefix, then ↑/↓ cycles only history
  entries matching that prefix (bound to the standard arrow keys).
- `vanilli.sh` additionally sets `auto_cd` (typing a bare directory name
  `cd`s into it), `auto_pushd` (every `cd` pushes onto the directory stack —
  use `popd`/`dirs -v` to navigate back), and smarter case-insensitive/
  partial-word completion matching.

## History

- `dotDir` — and therefore `.zsh_history` — lives under `~/.config/zsh`, not
  directly in `$HOME`.
- History is shared across concurrent sessions and appended rather than
  overwritten on exit, timestamped, and deduplicated on both search and save.

## direnv

`nix-direnv` is enabled with a custom `direnv_layout_dir` that hashes the
project path into `$XDG_CACHE_HOME/direnv/layouts/` instead of nix-direnv's
default per-project `.direnv/`. Set `mdarocha.zsh.autoDirenvAllow = true` to
auto-`direnv allow` any `.envrc` found on shell start — this trusts arbitrary
`.envrc` files without prompting, so only enable it on machines/directories
you already trust.

## `command-not-found` via nix-index

Instead of nixpkgs' `programs.command-not-found` (a periodic snapshot the
user has to fetch manually), `nix-index/` downloads a prebuilt index from
Mic92's `nix-index-database` release the first time a lookup runs, then
reuses it. It doesn't provide a `nix-index` binary; run
`nix run nixpkgs#nix-index` if you want to build your own index instead of
the community one.

## Extra keybindings and plugins

- `sudo` (oh-my-zsh) — press <kbd>Esc</kbd> <kbd>Esc</kbd> to prepend `sudo`
  to the current or previously run command line.
- `extract` (oh-my-zsh) — `extract <file>` unpacks most archive formats
  without needing to know the right tool; `unzip`/`unrar`/`p7zip` are
  installed to back it.
- `systemd` (oh-my-zsh) — `sc-*`/`scu-*` aliases for `systemctl`/
  `systemctl --user` (e.g. `sc-status foo.service`, `scu-restart foo.service`).
- On Ptyxis, `Home`/`End`/`Delete` are rebound to work around its
  non-standard escape sequences — only applied when `$PTYXIS_VERSION` is set.

## Local overrides

`~/.zshrc.local`, if present, is sourced last — use it for host-specific
tweaks that shouldn't go in the repo.
