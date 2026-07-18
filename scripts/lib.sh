#!/usr/bin/env bash

# determine the configuration based on the environment
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

export CONFIGURATION
