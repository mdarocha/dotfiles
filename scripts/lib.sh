#!/usr/bin/env bash

CONFIGURATION=""

if [[ "${CODESPACES:-}" == "true" ]]; then
    CONFIGURATION="codespace"
fi

if [[ "${WSL_DISTRO_NAME:-}" != "" ]]; then
    CONFIGURATION="wsl"
fi

if [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]; then
    CONFIGURATION="claude"
fi

if [[ -f /etc/os-release ]] && grep -q '^ID=steamos' /etc/os-release; then
    echo "❌ SteamOS is unsupported." >&2
    exit 1
fi

if [[ -f /etc/NIXOS ]] || { [[ -f /etc/os-release ]] && grep -q '^ID=nixos' /etc/os-release; }; then
    CONFIGURATION="nixos"
fi

if [[ -z "$CONFIGURATION" ]]; then
    echo "❌ Unsupported environment: no matching home-manager configuration (expected codespace, wsl, claude or nixos)." >&2
    exit 1
fi

export CONFIGURATION

# mirrors `ghq.root` from config/git, which isn't readable yet on a first install
: "${GHQ_ROOT:=$HOME/Projekty}"
export GHQ_ROOT
