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
    if [ ! -f /nix/var/nix/profiles/default/bin/nix ]; then
        echo "🔨 Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
          sh -s -- install "$@" --no-confirm \
            --extra-conf "substituters = https://cache.nixos.org https://mdarocha-dotfiles.cachix.org" \
            --extra-conf "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k="
    else
        echo "✅ Nix is already installed."
    fi
}

install_nix_codespace_workarounds() {
    # Fixes issue with "suspicous owner or permissions" error
    if ! command -v setfacl &> /dev/null; then
        echo "🔨 Installing ACL..."
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends acl
        sudo rm -rf /var/lib/apt/lists/*
    fi

    sudo setfacl -k /tmp
}

install_nix_daemon_openrc_service() {
    echo "🔨 Installing nix-daemon OpenRC service..."
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
        docker run --privileged --rm tonistiigi/binfmt --install arm64,arm
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
        ;;
    "linux")
        install_nix linux \
            --extra-conf "extra-platforms = aarch64-linux arm-linux"
        ;;
    *)
        install_nix
        ;;
esac

echo "⚙️  Applying home-manager configuration..."
/nix/var/nix/profiles/default/bin/nix run .#apply

echo "⚙️  Changing the shell to nix-managed zsh..."
case "$CONFIGURATION" in
    "codespace")
        sudo chsh "$(id -un)" --shell "/home/codespace/.nix-profile/bin/zsh"
        ;;
    *)
        echo "⚠️  $CONFIGURATION doesn't support changing the shell. Make sure it's setup manually."
        ;;
esac

echo "✅ Done!"

popd > /dev/null || exit
