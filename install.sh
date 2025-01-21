#!/usr/bin/env bash

wait_for_docker() {
  echo "Waiting for Docker socket to become available..."
  while [ ! -S /var/run/docker.sock ]; do
    sleep 1
  done
  echo "Docker socket is now available."
}

install_nix() {
    if ! command -v nix &> /dev/null; then
        echo "🔨 Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
          sh -s -- install "$@" --no-confirm
    else
        echo "✅ Nix is already installed."
    fi
}

install_nix_codespace_workarounds() {
cat <<EOF >> /home/codespace/.bashrc
# Hacky workarounds to make Nix work in Codespaces over SSH
export PATH="/nix/var/nix/profiles/default/bin/:\${PATH}"
if ! pidof nix-daemon > /dev/null 2>&1; then
    sudo \$(which nix-daemon) &
fi
EOF

    # Fixes issue with "suspicous owner or permissions" error
    sudo apt update
    sudo apt install acl
    sudo setfacl -k /tmp
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

echo "✅ Done!"
