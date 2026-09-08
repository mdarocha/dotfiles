#!/usr/bin/env bash

CONFIGURATION="linux"

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
    CONFIGURATION="deck"
fi

if [[ -f /etc/NIXOS ]] || { [[ -f /etc/os-release ]] && grep -q '^ID=nixos' /etc/os-release; }; then
    CONFIGURATION="nixos"
fi

export CONFIGURATION

# mirrors `ghq.root` from config/git, which isn't readable yet on a first install
if [[ -z "${GHQ_ROOT:-}" ]]; then
    case "$CONFIGURATION" in
        "deck")
            GHQ_ROOT="$HOME/sdcard/projects"
            ;;
        *)
            GHQ_ROOT="$HOME/Projekty"
            ;;
    esac
fi

export GHQ_ROOT
