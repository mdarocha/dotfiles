#!/usr/bin/env zsh

autoload -Uz colors && colors
autoload -U add-zsh-hook

blockline_setup() {
    setopt prompt_subst
    setopt prompt_percent
}

blockline_solarized_colors() {
    typeset -AHg SOL_FG SOL_BG

    SOL_FG[base03]="%F{234}"
    SOL_FG[base02]="%F{235}"
    SOL_FG[base01]="%F{240}"
    SOL_FG[base00]="%F{241}"
    SOL_FG[base0]="%F{244}"
    SOL_FG[base1]="%F{245}"
    SOL_FG[base2]="%F{254}"
    SOL_FG[base3]="%F{230}"
    SOL_FG[yellow]="%F{136}"
    SOL_FG[orange]="%F{166}"
    SOL_FG[red]="%F{160}"
    SOL_FG[magenta]="%F{125}"
    SOL_FG[violet]="%F{61}"
    SOL_FG[blue]="%F{33}"
    SOL_FG[cyan]="%F{37}"
    SOL_FG[green]="%F{64}"

    SOL_BG[base03]="%K{234}"
    SOL_BG[base02]="%K{235}"
    SOL_BG[base01]="%K{240}"
    SOL_BG[base00]="%K{241}"
    SOL_BG[base0]="%K{244}"
    SOL_BG[base1]="%K{245}"
    SOL_BG[base2]="%K{254}"
    SOL_BG[base3]="%K{230}"
    SOL_BG[yellow]="%K{136}"
    SOL_BG[orange]="%K{166}"
    SOL_BG[red]="%K{160}"
    SOL_BG[magenta]="%K{125}"
    SOL_BG[violet]="%K{61}"
    SOL_BG[blue]="%K{33}"
    SOL_BG[cyan]="%K{37}"
    SOL_BG[green]="%K{64}"

    RESET_BG="%{%k%}"
    RESET_FG="%{%f%}"

    TEXT_COLOR="$SOL_FG[base3]"
}

blockline_nix() {
    local -r symbol_nix='󱄅'
    local -r symbol_direnv=''

    # show if direnv active
    if [[ -n $DIRENV_DIR ]]; then
        echo "$SOL_BG[violet] ${symbol_direnv} direnv $RESET_BG"
        return
    fi

    # show if in nix shell
    if echo "$PATH" | grep -qc '/nix/store'; then
        echo "$SOL_BG[violet] ${symbol_nix} nix $RESET_BG"
        return
    fi

    # show in in legacy nix-shell
    if [[ -n $IN_NIX_SHELL ]]; then
        echo "$SOL_BG[violet] ${symbol_nix} nix $RESET_BG"
        return
    fi
}

blockline_python_venv() {
    local -r symbol_python=''

    if [ -n "$VIRTUAL_ENV" ]; then
        echo "$SOL_BG[violet] ${symbol_python} $(basename ${VIRTUAL_ENV}) $RESET_BG"
    fi
}

blockline_ssh() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        HOST=" $(cat /etc/hostname)"
        if [[ "${CODESPACES}" == "true" ]]; then
            HOST=" ${CODESPACE_NAME%-*}"
        fi
        echo "$SOL_BG[violet] $HOST $RESET_BG"
    fi
}

blockline_jobs() {
    local jobs_count=$(jobs | wc -l)
    if [ $jobs_count -ne 0 ]; then
        echo "$SOL_BG[yellow] $jobs_count $RESET_BG"
    fi
}

blockline_vcs_info() {
    local branch=$'\ue0a0'
    local merging="m"

    local staged="+"
    local modified="!"
    local untracked="."

    local ahead="⇡ NUM"
    local behind="⇣ NUM"


    ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return


    local git_location=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}


    local -a divergencies

    local num_ahead="$(git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$num_ahead" -gt 0 ]; then
        divergencies+=("${ahead//NUM/$num_ahead}")
    fi

    local num_behind="$(git log --oneline ..@{u} 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$num_behind" -gt 0 ]; then
        divergencies+=("${behind//NUM/$num_behind}")
    fi


    local -a flags

    local git_dir="$(git rev-parse --git-dir 2> /dev/null)"
    if [ -n $git_dir ] && test -r $git_dir/MERGE_HEAD; then
        flags+=("$merging")
    fi

    if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
        flags+=("$untracked")
    fi

    if ! git diff --quiet 2> /dev/null; then
        flags+=("$modified")
    fi

    if ! git diff --cached --quiet 2> /dev/null; then
        flags+=("$staged")
    fi



    local -a git_info
    git_info+=("$branch $git_location")
    [[ ${#flags[@]} -ne 0 ]] && git_info+=("${(j::)flags}")
    [[ ${#divergencies[@]} -ne 0 ]] && git_info+=("${(j::)divergencies}")

    echo "$SOL_BG[blue] ${(j: :)git_info} $RESET_BG"
}

blockline() {
    blockline_setup
    blockline_solarized_colors

    local block_prompt=""

    # ssh info
    block_prompt+="$(blockline_ssh)"

    # nix info
    block_prompt+="$(blockline_nix)"

    # python env info
    block_prompt+="$(blockline_python_venv)"

    # prompt directory
    block_prompt+="$SOL_BG[base1] %3~ $RESET_BG"

    # jobs count
    block_prompt+="$(blockline_jobs)"

    # version control info
    block_prompt+="$(blockline_vcs_info)"

    # prompt char
    local symbol_color="%(?.$SOL_BG[green].$SOL_BG[red])"
    block_prompt+="$symbol_color $ $RESET_BG"

    PROMPT="$TEXT_COLOR${block_prompt} $RESET_FG"
    RPROMPT=""
}

add-zsh-hook precmd blockline
