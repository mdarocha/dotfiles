# dotfiles

This repository contains my personal dotfiles.
It's managed using [Home Manager](https://github.com/nix-community/home-manager/).

Nix derivations on the `main` branch are built by Github Actions and pushed to the [Cachix cache](https://app.cachix.org/cache/mdarocha-dotfiles#pull).

## Installation

To install the dotfiles, clone the repository and run the `install.sh` script.

```bash
$ ./install.sh
```

The script will:
  1. Install `binfmt` support for ARM systems
     
     > This is currently only supported when running on GitHub Codespaces and uses the [tonistiigi/binfmt](https://github.com/tonistiigi/binfmt) Docker image

  1. Install Nix using the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)
     
     > It will setup the [mdarocha-dotfiles](https://app.cachix.org/cache/mdarocha-dotfiles) Nix binary cache, which is updated by GitHub Actions in this repository.
     > 
     > On GitHub Codespaces, it uses `--init none`, since Codespaces use `/etc/init.d` instead of `systemd` services.
        
  1. _Codespaces only_: Install the `/etc/init.d/nix-daemon` script to manage `nix-daemon` using `init.d` and start it.
  1. _Codespaces only_: Run various workarounds for problems found running Nix in codespaces
     - `"error: suspicious ownership or permission"` when running `nix build` - fixed with `sudo setfacl -k /tmp`
       
        > See https://github.com/digitallyinduced/ihp/issues/1706#issuecomment-1605415702 and https://github.com/mpscholten/TestIHPJune22/blob/c6d76d61d9b57778b1e8b2d1ff2d896c88395769/.devcontainer/devcontainer.json#L21

  1. Run `nix run .#apply` to apply `home-manager` configurations from the flake
     
## Configurations

The `flake.nix` file contains several configurations, depending on what environment we
install the dotfiles.

| Configuration | Description |
| :-- | :-- |
| `homeConfigurations.linux` | For native Linux systems. |
| `homeConfigurations.codespace` | For GitHub Codespaces. |
| `homeConfigurations.wsl` | For Windows Subsystem for Linux. (🚧 TODO) |

## Additional configurations

Some configurations include dotfiles for software that is not installed by Home Manager.
These are optional — install only what you want to use.

### Ghostty

[Ghostty](https://ghostty.org/) can be installed via your system package manager, Flatpak,
or AppImage. Home Manager will write the config regardless.

### Hack Nerd Font

The Ghostty config uses the **Hack Nerd Font**. If you use Ghostty, you may want to install it
from the [Nerd Fonts website](https://www.nerdfonts.com/font-downloads).
Place the font files under `~/.local/share/fonts/` and run `fc-cache -f`.

### Zed

[Zed](https://zed.dev/) can be installed via your system package manager or the official
installer. Home Manager will write the config regardless.
