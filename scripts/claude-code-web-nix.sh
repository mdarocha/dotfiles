#!/usr/bin/env bash

nix_bin=/nix/var/nix/profiles/default/bin

if [[
    "${CLAUDE_CODE_REMOTE:-}" == "true" &&
    -x "$nix_bin/nix" &&
    -n "${CLAUDE_ENV_FILE:-}" &&
    -w "$CLAUDE_ENV_FILE"
]] && ! command -v nix >/dev/null 2>&1; then
    printf '%s\n' "export PATH=\"$nix_bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
