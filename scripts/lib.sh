#!/usr/bin/env bash

# determine the configuration based on the environment
CONFIGURATION="linux"

if [[ "${CODESPACES:-}" == "true" ]]; then
    CONFIGURATION="codespace"
fi

export CONFIGURATION
