# dotfiles

This repository contains my personal dotfiles.
It's managed using [Home Manager](https://github.com/nix-community/home-manager/).

## Installation

To install the dotfiles, clone the repository and run the `install.sh` script.

```bash
$ ./install.sh
```

The script will take care of making sure that [Nix](https://nixos.org) is installed,
and activating the relevant Home Manager configuration in `flake.nix`.

## Configurations

The `flake.nix` file contains several configurations, depending on what environment we
install the dotfiles.

| `linux` | For native Linux systems. |
| `codespace` | For GitHub Codespaces. |
| `wsl` | For Windows Subsystem for Linux. (🚧 TODO) |
