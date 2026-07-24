#!/bin/bash
set -euo pipefail

# Claude Code's Bash tool runs non-interactive, non-login shells, so it
# never sources the profile.d scripts that would normally put Nix on PATH
# (and in some containers those scripts are also preset to no-op via
# __ETC_PROFILE_NIX_SOURCED). Fix PATH directly instead of relying on either.
NIX_BIN="/nix/var/nix/profiles/default/bin"
if [ -x "$NIX_BIN/nix" ] && ! command -v nix >/dev/null 2>&1; then
    echo "export PATH=\"$NIX_BIN:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
