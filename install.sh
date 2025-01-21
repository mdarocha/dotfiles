#!/usr/bin/env bash

echo "Hello!"
echo "======"

echo "🔨 Installing Nix..."

if ! command -v nix &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
      sh -s -- install --no-confirm
    echo "🔨 Nix installed."
else
    echo "🔨 Nix is already installed."
fi
