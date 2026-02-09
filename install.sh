#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null || exit

NIX_COMMAND=""
NIX_SHELL_COMMAND=""

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
    NIX_SHELL_COMMAND="/nix/var/nix/profiles/default/bin/nix-shell"
}

install_nix_portable() {
    if which nix >/dev/null 2>&1 || [ -d /nix ]; then
        echo "⚠️  Nix is already installed on this system. Skipping install."
        return
    fi

    if [ -f ./nix-portable ]; then
        echo "✅ nix-portable is already downloaded."
    else
        echo "🔨 Downloading nix-portable..."
        curl --proto '=https' --tlsv1.2 -sSf -L \
            -o ./nix-portable \
            https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64
        echo "✅ nix-portable downloaded."
    fi

    chmod +x ./nix-portable

    export NP_GIT="$(which git)"
    export NP_RUNTIME="proot"
    
    NIX_COMMAND="$(pwd)/nix-portable nix"
    NIX_SHELL_COMMAND="$(pwd)/nix-portable nix-shell"
}

install_nix_codespace_workarounds() {
    # Fixes issue with "suspicous owner or permissions" error
    if ! command -v setfacl &> /dev/null; then
        echo "🔨 Installing ACL..."
        sudo apt-get update || true
        sudo apt-get install -y --no-install-recommends acl
        echo "✅ ACL installed."
    fi

    echo "🔨 Setting /tmp ACLs..."
    sudo setfacl -k /tmp
    echo "✅ /tmp ACLs set."
}

generate_shell_wrapper() {
    # pre-warm nix-shell invocation to make sure its cached
    ./nix-portable nix-shell -p nix --command "echo 'Nix shell warmed up'"

cat <<EOF > ./zsh-wrapper.sh
#!/usr/bin/env bash

export NP_GIT="$(which git)"
export NP_RUNTIME="proot"

export PATH="\$HOME/.nix-profile/bin:\$PATH"
exec "$(pwd)/nix-portable" nix-shell -p nix --command zsh
EOF

    chmod +x ./zsh-wrapper.sh
}
echo "👋 Hello!"
echo "======"

# shellcheck disable=SC1091
source ./scripts/lib.sh

echo "🔨 Setting up for $CONFIGURATION..."

echo "⚙️  Setting up Nix..."
case "$CONFIGURATION" in
    "codespace")
        install_nix_codespace_workarounds
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

echo "🔨 Building the home-manager activation package..."
$NIX_COMMAND build .#homeConfigurations."$CONFIGURATION".activationPackage \
    --extra-substituters "https://cache.nixos.org https://mdarocha-dotfiles.cachix.org" \
    --extra-trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= mdarocha-dotfiles.cachix.org-1:kBGT+0RREXqBc0Z7hI9NdvjrA7ypIpIhMLNrD1qLF9k=" \
    --out-link "./activation"
echo "✅ Build successful."

echo "🔨 Activating the home-manager configuration..."
while [ "$attempt" -le "$retries" ]; do
    echo "Attempt $attempt/$retries..."

    export HOME_MANAGER_BACKUP_EXT=backup
    if $NIX_SHELL_COMMAND -p nix --command ./activation/activate; then
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
        generate_shell_wrapper
        wrapper_path="$(pwd)/zsh-wrapper.sh"
        sudo chsh "$(id -un)" --shell "$wrapper_path"
        sudo ln -sf "$wrapper_path" "/usr/local/bin/zsh"
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
