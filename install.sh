#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null || exit

wait_for_docker() {
  if docker version > /dev/null 2>&1; then
    echo "Docker is already available"
    return
  fi

  echo "Waiting for Docker to become available..."
  until docker version > /dev/null 2>&1; do
    sleep 1
  done

  sleep 1
  echo "Docker socket is now available."
}

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
    # Fixes issue with "suspicous owner or permissions" error
    if ! command -v setfacl &> /dev/null; then
        echo "🔨 Installing ACL..."
        sudo apt-get update || true
        sudo apt-get install -y --no-install-recommends acl
        sudo rm -rf /var/lib/apt/lists/*
    fi

    sudo setfacl -k /tmp
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

echo "⚙️  Installing binfmt support..."
case "$CONFIGURATION" in
    "codespace")
        wait_for_docker
        docker run --privileged --rm tonistiigi/binfmt --install arm64,arm || true
        ;;
    *)
        echo "⚠️  $CONFIGURATION doesn't support binfmt setup. Make sure it's setup manually"
        ;;
esac

echo "⚙️  Setting up Nix..."
case "$CONFIGURATION" in
    "codespace")
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

unset __ETC_PROFILE_NIX_SOURCED
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

retries=3
delay=3
attempt=1

while [ "$attempt" -le "$retries" ]; do
    echo "Attempt $attempt/$retries..."

    if /nix/var/nix/profiles/default/bin/nix run .#apply; then
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
    "wsl")
        if ! grep "/home/$USER/.nix-profile/bin/zsh" "/etc/shells"; then
            echo "/home/$USER/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
        fi
        chsh --shell "/home/$USER/.nix-profile/bin/zsh"
        echo "✅ Shell changed. Re-login to see results"
        ;;
    *)
        echo "⚠️  $CONFIGURATION doesn't support changing the shell. Make sure it's setup manually."
        ;;
esac

echo "✅ Done!"

popd > /dev/null || exit
