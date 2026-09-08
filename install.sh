#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

export USER="${USER:-$(id -un)}"

# Support running via curl | bash: if not executing from a file, fetch the repo first
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    REPO_URL="https://github.com/mdarocha/dotfiles"

    staging="$(mktemp -d)"
    trap 'rm -rf "$staging"' EXIT

    echo "📥 Fetching dotfiles..."
    if command -v git > /dev/null 2>&1; then
        git clone "$REPO_URL" "$staging/dotfiles"
    else
        mkdir -p "$staging/dotfiles"
        curl --proto '=https' --tlsv1.2 -sSf -L "$REPO_URL/archive/refs/heads/main.tar.gz" \
            | tar -xz -C "$staging/dotfiles" --strip-components=1
    fi

    # shellcheck disable=SC1091
    source "$staging/dotfiles/scripts/lib.sh"
    DOTFILES_DIR="${DOTFILES_DIR:-$GHQ_ROOT/github.com/mdarocha/dotfiles}"

    if [[ ! -f "$DOTFILES_DIR/install.sh" ]]; then
        echo "📂 Placing dotfiles in $DOTFILES_DIR..."
        mkdir -p "$(dirname "$DOTFILES_DIR")"
        mv "$staging/dotfiles" "$DOTFILES_DIR"
    fi

    rm -rf "$staging"
    exec bash "$DOTFILES_DIR/install.sh"
fi

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null || exit

install_nix() {
    if which nix >/dev/null 2>&1 || [ -d /nix ] || [ -f /nix/var/nix/profiles/default/bin/nix ]; then
        echo "✅ Nix is already installed."
        return
    fi
    
    echo "🔨 Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install "$@" --no-confirm \
            --extra-conf "trusted-users = $USER" \
            --extra-conf "substituters = https://cache.nixos.org https://mdarocha-dotfiles.cachix.org" \
            --extra-conf "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k="
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

# shellcheck disable=SC1091
source ./scripts/lib.sh

echo "🔨 Setting up for $CONFIGURATION..."

echo "⚙️  Setting up Nix..."
case "$CONFIGURATION" in
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
    "nixos")
        echo "✅ Nix is managed by the NixOS system."
        ;;
    *)
        install_nix
        ;;
esac

echo "⚙️  Applying home-manager configuration..."

if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    unset __ETC_PROFILE_NIX_SOURCED
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

nix_bin="/nix/var/nix/profiles/default/bin/nix"
if [ ! -x "$nix_bin" ]; then
    nix_bin="nix"
fi

# NixOS ships without flakes enabled, and the nested `nix run` in .#apply needs them too
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

retries=3
delay=3
attempt=1

while [ "$attempt" -le "$retries" ]; do
    echo "Attempt $attempt/$retries..."

    if "$nix_bin" run --accept-flake-config .#apply; then
        break
    fi
    status=$?

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
        echo "⚠️  On NixOS the shell is declarative - set programs.zsh.enable and users.users.$USER.shell in your system config."
        ;;
    *)
        echo "⚠️  $CONFIGURATION doesn't support changing the shell. Make sure it's setup manually."
        ;;
esac

echo "✅ Done!"

popd > /dev/null || exit
