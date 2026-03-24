---
name: run-with-nix
description: Find and run programs that aren't installed on the system using nix-locate and nix run, without permanently installing anything.
---

# Run programs with Nix

When a program is not found on the system, use `nix-locate` to find which Nix package provides it, then use `nix run` to run it directly without installing it.

> **Important:** `nix` and `nix-locate` should already be installed and configured. If either command fails due to missing installation, notify the user and do not attempt to install or configure them yourself.

## Workflow

1. When a command is not found, use `nix-locate` to find the package that provides it.
2. Use `nix run` to run the program from that package.

## Finding packages with nix-locate

`nix-locate` searches a pre-built index of Nix packages to find which package provides a given file.

```bash
# Find which package provides a binary
nix-locate --whole-name 'bin/jq'

# Find which package provides a binary (minimal output - just attribute names)
nix-locate --whole-name --minimal 'bin/jq'

# Search for any file matching a pattern
nix-locate 'bin/firefox'

# Use regex for more flexible matching
nix-locate --regex 'bin/python3\.[0-9]+'

# Only search for executable files
nix-locate --whole-name --type x 'bin/rg'

# Filter results to a specific package name
nix-locate --whole-name 'bin/gs' --package ghostscript
```

### Reading nix-locate output

Output lines look like this:

```
jq.out                                        6,144 x /nix/store/...-jq-1.7.1/bin/jq
```

The first column is the Nix attribute path (e.g. `jq`). The `.out` suffix is the output name and can be ignored. Use the attribute name with `nix run` as `nixpkgs#<attribute>`.

If the attribute is wrapped in parentheses like `(some-package.out)`, it means the exact attribute path is uncertain — the package is a dependency of `some-package` rather than `some-package` itself. In that case, try running it anyway, or search more specifically.

### Tips

- Always use `--whole-name` with `bin/<name>` to get precise results and avoid matching unrelated files.
- Use `--minimal` when you just need the attribute name for `nix run`.
- Use `--type x` to only match executable files.

## Running programs with nix run

`nix run` builds and runs a program from a flake without installing it. The program is cached in the Nix store, so subsequent runs are fast.

```bash
# Run a program from nixpkgs
nix run nixpkgs#jq -- --help

# Run a program from nixpkgs (everything after -- is passed to the program)
nix run nixpkgs#ripgrep -- -i 'pattern' ./src

# Run a program from any flake
nix run github:owner/repo

# Run a specific program from a flake with multiple outputs
nix run nixpkgs#python3 -- -c "print('hello')"
```

### How nix run finds the binary

When you run `nix run nixpkgs#<name>`, Nix builds the package and then looks for an executable in `$out/bin/` using this priority:

1. `meta.mainProgram` attribute of the package
2. `pname` attribute of the package
3. The name part of the `name` attribute

This means `nix run nixpkgs#ripgrep` runs `rg` (because `meta.mainProgram = "rg"`), not `ripgrep`.

If the binary name doesn't match the package name, you can still run it — `nix run` handles this automatically via `meta.mainProgram`.

## Full example

```bash
# Command not found: "rg"
# Step 1: Find the package
$ nix-locate --whole-name --minimal 'bin/rg'
ripgrep.out

# Step 2: Run it
$ nix run nixpkgs#ripgrep -- -i 'TODO' ./src
```

```bash
# Command not found: "http" (httpie)
# Step 1: Find the package
$ nix-locate --whole-name --minimal 'bin/http'
httpie.out
python3Packages.httpie.out

# Step 2: Run it (pick the most specific match)
$ nix run nixpkgs#httpie -- GET https://example.com
```
