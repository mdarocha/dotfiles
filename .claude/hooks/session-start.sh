#!/bin/bash
set -euo pipefail

# Claude Code on the web containers already have Nix installed, but its bin
# directory isn't on PATH by default (the profile.d scripts no-op because
# __ETC_PROFILE_NIX_SOURCED is preset in the base image). Just fix PATH here
# — do not run install.sh's full setup (installer, binfmt, home-manager
# apply); it isn't needed on the web.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
    exit 0
fi

NIX_BIN="/nix/var/nix/profiles/default/bin"
if [ -x "$NIX_BIN/nix" ] && ! command -v nix >/dev/null 2>&1; then
    echo "export PATH=\"$NIX_BIN:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
