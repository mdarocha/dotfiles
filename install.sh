#!/usr/bin/env bash

install_nix() {
    if ! command -v nix &> /dev/null; then
        echo "🔨 Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
          sh -s -- install "$@" --no-confirm
    else
        echo "✅ Nix is already installed."
    fi
}

echo "👋 Hello!"
echo "======"

CONFIGURATION="linux"

if [[ "$CODESPACES" == "true" ]]; then
    CONFIGURATION="codespace"
fi

echo "🔨 Setting up for $CONFIGURATION..."

echo "⚙️  Installing binfmt support..."
case "$CONFIGURATION" in
    "codespace")
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
        ;;
    "linux")
        install_nix linux \
            --extra-conf "extra-platforms = aarch64-linux arm-linux"
        ;;
    *)
        install_nix
        ;;
esac
