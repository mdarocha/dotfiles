---
name: run-with-nix
description: Run an unavailable program temporarily with Nix. Use a known nixpkgs package directly; otherwise look up the executable with nix-index without installing it into a user profile.
---

# Run programs with Nix

Use Nix only after confirming that a required command is unavailable. `nix` is available in this environment. Do not install packages into a user profile.

## Known package

When the nixpkgs package is known, run it directly:

```bash
nix run nixpkgs#jq -- --help
nix run nixpkgs#ripgrep -- -i 'pattern' ./src
nix shell nixpkgs#python3 --command python -c "print('hello')"
```

`nix run` starts the package's configured main program. Use `nix shell … --command` when a specific executable is needed.

## Unknown package

`nix-locate` may not be on `PATH`, especially in a sandbox. Run it temporarily from `nix-index`; it uses the existing `~/.cache/nix-index/files` database when available.

```bash
# Find the package providing this exact executable path.
nix shell nixpkgs#nix-index --command nix-locate --whole-name --minimal --type x --at-root /bin/rg
```

The result's attribute path (for example, `ripgrep.out`) maps to `nixpkgs#ripgrep`; omit the output suffix. Prefer a direct, non-parenthesized attribute whose package name matches the command.

If the cached index is unavailable, report that exact executable lookup is unavailable. Use the known-package workflow when the package name is clear; do not build a new index or run a broad nixpkgs search.

If lookup or evaluation fails, report the error. Do not fall back to a profile installation.
