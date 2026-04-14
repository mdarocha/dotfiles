---
name: run-with-nix
description: Find and run programs that aren't installed on the system using nix-locate and nix run, without permanently installing anything. Use when a command is not found, a tool is missing, a binary is not in PATH, or the user asks to run something without installing it. Also use when encountering "command not found" errors, or when needing to find which Nix package provides a specific program. This skill should be used proactively whenever a program isn't available.
---

# Run programs with Nix

When a program is not found on the system, use `nix-locate` to find which Nix package
provides it, then use `nix run` to run it directly without installing.

> **Important:** `nix` and `nix-locate` should already be installed and configured.
> If either fails due to missing installation, notify the user and do not attempt to
> install or configure them yourself.

## Quick Workflow

```bash
# 1. Find the package
nix-locate --whole-name --minimal 'bin/<command>'

# 2. Run it (everything after -- is passed to the program)
nix run nixpkgs#<package> -- <args>
```

## Finding packages with nix-locate

```bash
# Precise lookup (preferred — always use --whole-name with bin/<name>)
nix-locate --whole-name --minimal 'bin/jq'

# Only match executables
nix-locate --whole-name --type x 'bin/rg'

# Regex for flexible matching
nix-locate --regex 'bin/python3\.[0-9]+'

# Verbose output (shows file sizes and paths)
nix-locate --whole-name 'bin/jq'
```

### Reading nix-locate output

```
jq.out                                        6,144 x /nix/store/...-jq-1.7.1/bin/jq
```

- First column is the Nix attribute path (e.g. `jq`). The `.out` suffix can be ignored.
- Use the attribute name with `nix run` as `nixpkgs#<attribute>`.
- If wrapped in parentheses like `(some-package.out)`, the path is uncertain — it's a
  dependency rather than the package itself. Try it anyway, or search more specifically.

### Choosing between multiple results

When `nix-locate` returns multiple matches, prefer:
1. The shortest/simplest attribute name (e.g. `httpie` over `python3Packages.httpie`)
2. The one that isn't wrapped in parentheses
3. The one whose package name most closely matches the binary name

## Running programs with nix run

```bash
# Run from nixpkgs
nix run nixpkgs#jq -- --help
nix run nixpkgs#ripgrep -- -i 'pattern' ./src
nix run nixpkgs#python3 -- -c "print('hello')"

# Run from any flake
nix run github:owner/repo
```

### How nix run finds the binary

`nix run nixpkgs#<name>` looks for an executable in `$out/bin/` using this priority:
1. `meta.mainProgram` attribute
2. `pname` attribute
3. The name part of the `name` attribute

This means `nix run nixpkgs#ripgrep` runs `rg` (because `meta.mainProgram = "rg"`), not `ripgrep`.

## Error handling

- **nix-locate returns nothing:** The nix-index database may be out of date, or the program
  may not be packaged in nixpkgs. Inform the user. They can update the index with `nix-index`.
- **nix run fails to build:** The package may be broken or unsupported on the current platform.
  Check the error message and inform the user.
- **Wrong binary runs:** If `nix run` launches the wrong program (name mismatch), the user
  can run a specific binary directly: `nix shell nixpkgs#<package> --command <binary> <args>`

## Examples

```bash
# Command not found: "rg"
$ nix-locate --whole-name --minimal 'bin/rg'
ripgrep.out
$ nix run nixpkgs#ripgrep -- -i 'TODO' ./src

# Command not found: "http" (httpie)
$ nix-locate --whole-name --minimal 'bin/http'
httpie.out
python3Packages.httpie.out
$ nix run nixpkgs#httpie -- GET https://example.com
```
