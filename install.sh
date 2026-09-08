#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

export USER="${USER:-$(id -un)}"

# Support running via curl | bash: if not executing from a file, clone the repo first
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        echo "📥 Cloning dotfiles repository to $DOTFILES_DIR..."
        git clone https://github.com/mdarocha/dotfiles "$DOTFILES_DIR"
    fi
    exec bash "$DOTFILES_DIR/install.sh"
fi

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null || exit

install_nix() {
    if load_nix; then
        echo "✅ Nix is already installed."
        return
    fi

    if [[ -e /nix ]]; then
        echo "Found /nix but no usable nix command; repair the existing Nix installation." >&2
        exit 1
    fi

    echo "🔨 Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install "$@" --no-confirm \
            --extra-conf "trusted-users = $USER" \
            --extra-conf "substituters = https://cache.nixos.org https://mdarocha-dotfiles.cachix.org" \
            --extra-conf "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k="

    if ! load_nix; then
        echo "Nix installation completed without a usable nix command." >&2
        exit 1
    fi
}

install_nix_codespace_workarounds() {
    # Fixes issue with "suspicious owner or permissions" error
    if ! command -v setfacl &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            echo "🔨 Installing ACL..."
            sudo apt-get update || true
            sudo apt-get install -y --no-install-recommends acl
            sudo rm -rf /var/lib/apt/lists/*
        fi
    fi

    if command -v setfacl &> /dev/null; then
        sudo setfacl -k /tmp
    fi
}

install_nix_daemon_initd_service() {
    if [ -f /etc/init.d/nix-daemon ]; then
        echo "✅ /etc/init.d/nix-daemon is already installed."
        return
    fi

    echo "🔨 Installing nix-daemon init.d service..."
    sudo cp ./scripts/nix-daemon.initd /etc/init.d/nix-daemon
    sudo chown root:root /etc/init.d/nix-daemon
    sudo chmod 755 /etc/init.d/nix-daemon

    echo "💨 Starting nix-daemon service..."
    sudo service nix-daemon start
}

echo "👋 Hello!"
echo "======"

source ./scripts/lib.sh
CONFIGURATION="$(detect_configuration)"
export CONFIGURATION

echo "🔨 Setting up for $CONFIGURATION..."

echo "⚙️  Setting up Nix..."
case "$CONFIGURATION" in
    "nixos")
        if ! load_nix; then
            echo "NixOS must provide a working nix command." >&2
            exit 1
        fi
        ;;
    "codespace" | "claude")
        install_nix linux \
            --init none \
            --extra-conf "extra-platforms = aarch64-linux arm-linux"

        install_nix_codespace_workarounds
        install_nix_daemon_initd_service
        ;;
    "linux" | "wsl")
        install_nix linux \
            --extra-conf "extra-platforms = aarch64-linux arm-linux"
        ;;
    *)
        install_nix
        ;;
esac

echo "⚙️  Applying home-manager configuration..."

if ! load_nix; then
    echo "No usable nix command after bootstrap." >&2
    exit 1
fi

retries=3
delay=3
attempt=1

while [ "$attempt" -le "$retries" ]; do
    echo "Attempt $attempt/$retries..."

    if nix run --accept-flake-config .#apply; then
        break
    else
        status=$?
    fi

    if [ "$attempt" -lt "$retries" ]; then
        echo "Configuration apply failed (exit $status). Retrying in $delay seconds..."
        sleep "$delay"
    else
        echo "Configuration apply failed after $retries attempts (exit $status)."
        exit "$status"
    fi
    attempt=$((attempt + 1))
done

echo "⚙️  Changing the shell to nix-managed zsh..."
case "$CONFIGURATION" in
    "codespace")
        sudo chsh "$(id -un)" --shell "/home/codespace/.nix-profile/bin/zsh"
        ;;
    "claude")
        sudo chsh "$(id -un)" --shell "/home/$USER/.nix-profile/bin/zsh"
        ;;
    "wsl")
        if ! grep "/home/$USER/.nix-profile/bin/zsh" "/etc/shells"; then
            echo "/home/$USER/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
        fi
        chsh --shell "/home/$USER/.nix-profile/bin/zsh"
        echo "✅ Shell changed. Re-login to see results"
        ;;
    "nixos")
        echo "NixOS user configuration owns the login shell."
        ;;
    *)
        echo "⚠️  $CONFIGURATION doesn't support changing the shell. Make sure it's setup manually."
        ;;
esac

echo "✅ Done!"

popd > /dev/null || exit
