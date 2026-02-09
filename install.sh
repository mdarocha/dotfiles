#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null || exit

NIX_COMMAND=""

install_nix() {
    if [ ! -f /nix/var/nix/profiles/default/bin/nix ]; then
        echo "🔨 Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
          sh -s -- install "$@" --no-confirm \
            --extra-conf "trusted-users = $USER" \
            --extra-conf "substituters = https://cache.nixos.org https://mdarocha-dotfiles.cachix.org" \
            --extra-conf "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k="
    else
        echo "✅ Nix is already installed."
    fi

    unset __ETC_PROFILE_NIX_SOURCED
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

    NIX_COMMAND="/nix/var/nix/profiles/default/bin/nix"
}

install_nix_portable() {
    if [ -f ./bin/nix-portable ]; then
        echo "✅ nix-portable is already downloaded."
    else
        mkdir -p ./bin
        echo "🔨 Downloading nix-portable..."
        curl --proto '=https' --tlsv1.2 -sSf -L \
            -o ./bin/nix-portable \
            https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64
    fi

    chmod +x ./bin/nix-portable

    export NP_GIT="$(which git)"
    export NP_RUNTIME=proot

    rm ./bin/nix && ln -s $(pwd)/bin/nix-portable ./bin/nix
    rm ./bin/nix-build && ln -s $(pwd)/bin/nix-portable ./bin/nix-build

    export PATH="$PATH:$(pwd)/bin"

    NIX_COMMAND="$(pwd)/bin/nix"
}

echo "👋 Hello!"
echo "======"

# shellcheck disable=SC1091
source ./scripts/lib.sh

echo "🔨 Setting up for $CONFIGURATION..."

echo "⚙️  Setting up Nix..."
case "$CONFIGURATION" in
    "codespace")
        install_nix_portable
        ;;
    "linux" | "wsl")
        install_nix linux \
            --extra-conf "extra-platforms = aarch64-linux arm-linux"
        ;;
    *)
        install_nix
        ;;
esac
echo "✅ Nix installed at $NIX_COMMAND"

echo "⚙️  Applying home-manager configuration..."
retries=3
delay=3
attempt=1

$NIX_COMMAND build .#homeConfigurations."$CONFIGURATION".activationPackage \
    --extra-substituters "https://cache.nixos.org https://mdarocha-dotfiles.cachix.org" \
    --extra-trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k=" \
    --out-link "./activation"

while [ "$attempt" -le "$retries" ]; do
    echo "Attempt $attempt/$retries..."

    if $NIX_COMMAND shell nixpkgs#nix --command ./activation/activate; then
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
echo "✅ Home-manager configuration applied successfully."

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
echo "✅ Shell changed for $CONFIGURATION."

echo "✅ Done!"

popd > /dev/null || exit
