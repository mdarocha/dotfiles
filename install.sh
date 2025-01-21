#!/usr/bin/env bash

echo "Hello!"
echo "======"

if [[ "$CODESPACES" == "true" ]]; then
    echo "Installing binfmt support..."
    docker run --privileged --rm tonistiigi/binfmt --install arm64,arm
fi

echo "🔨 Installing Nix..."

if ! command -v nix &> /dev/null; then
    if [[ "$CODESPACES" == "true" ]]; then
        echo "🔨 Installing Nix for Codespaces..."
        sh <(curl -L https://nixos.org/nix/install) --no-daemon

        echo 'if [ -e /home/codespace/.nix-profile/etc/profile.d/nix.sh ]; then . /home/codespace/.nix-profile/etc/profile.d/nix.sh; fi # added by dotfiles, required for Nix to work over ssh' >> ~/.bashrc

        sudo mkdir -p /etc/nix
        sudo touch /etc/nix/nix.conf
        echo 'sandbox = false' | sudo tee -a /etc/nix/nix.conf
        echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
        echo 'extra-platforms = aarch64-linux arm-linux' | sudo tee -a /etc/nix/nix.conf
    else
        echo "🔨 Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
          sh -s -- install --no-confirm
    fi
else
    echo "🔨 Nix is already installed."
fi
