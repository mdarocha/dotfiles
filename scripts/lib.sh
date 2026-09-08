#!/usr/bin/env bash

detect_configuration() {
    local os_release="${1:-/etc/os-release}"
    local id=""
    local line
    local value

    if [[ -r "$os_release" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            case "$line" in
                ID=*)
                    value="${line#ID=}"
                    case "$value" in
                        \"*\")
                            id="${value:1:-1}"
                            ;;
                        \'*\')
                            id="${value:1:-1}"
                            ;;
                        *)
                            id="$value"
                            ;;
                    esac
                    break
                    ;;
            esac
        done < "$os_release"
    fi

    if [[ "$id" == "steamos" ]]; then
        printf '%s\n' "deck"
    elif [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]; then
        printf '%s\n' "claude"
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        printf '%s\n' "wsl"
    elif [[ "${CODESPACES:-}" == "true" ]]; then
        printf '%s\n' "codespace"
    elif [[ "$id" == "nixos" ]]; then
        printf '%s\n' "nixos"
    else
        printf '%s\n' "linux"
    fi
}

load_nix() {
    local profile_root="${1:-/nix/var/nix/profiles/default}"
    local profile_script="$profile_root/etc/profile.d/nix-daemon.sh"
    local nix_bin="$profile_root/bin/nix"

    if command -v nix > /dev/null; then
        return 0
    fi

    if [[ -r "$profile_script" ]]; then
        unset __ETC_PROFILE_NIX_SOURCED
        if source "$profile_script"; then
            :
        fi
    fi

    if command -v nix > /dev/null; then
        return 0
    fi

    if [[ -x "$nix_bin" ]]; then
        PATH="$profile_root/bin:$PATH"
        export PATH
    fi

    command -v nix > /dev/null
}
