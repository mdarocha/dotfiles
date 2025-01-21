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
    else
        echo "🔨 Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
          sh -s -- install --no-confirm
    fi
else
    echo "🔨 Nix is already installed."
fi
