# ── Custom Prompt ──
# Author: Shreyas Ugemuge
#
# Features:
#   - Face indicator: [-_-] yellow on success, [O_O] red on error
#   - Git branch and dirty/staged status via vcs_info
#   - Modern color palette with clean layout
#
# Layout:
#   [-_-] (main)* user@host ~/path
#   $

# ── Git integration via vcs_info ──
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats '%F{green}(%b)%f%F{208}%u%c%f'
zstyle ':vcs_info:git*' actionformats '%F{green}(%b|%a)%f%F{208}%u%c%f'
zstyle ':vcs_info:git*' check-for-changes true
zstyle ':vcs_info:git*' unstagedstr '*'
zstyle ':vcs_info:git*' stagedstr '+'

# ── Face indicator ──
# Captures the exit code of the previous command BEFORE anything
# else runs, then sets the face accordingly.
#
# We use a dedicated function added to precmd_functions so it
# plays nicely with vcs_info and anything else hooked into precmd.

_prompt_face=""

function _set_face() {
    if [[ $? -eq 0 ]]; then
        _prompt_face="%F{yellow}-_-%f"
    else
        _prompt_face="%F{red}O_O%f"
    fi
}

_prompt_untracked=""

function _set_vcs_info() {
    vcs_info
    # Lightweight untracked-file check
    if [[ -n "${vcs_info_msg_0_}" ]] && git status --porcelain 2>/dev/null | grep -q '^??'; then
        _prompt_untracked="%F{208}?%f"
    else
        _prompt_untracked=""
    fi
}

# Hook both into precmd — face MUST come first to capture $?
# shellcheck disable=SC2034
# precmd_functions is a zsh special array called before each prompt; it IS used by zsh internals
precmd_functions=(_set_face _set_vcs_info)

# ── Color reference ──
# Face success : yellow       (status — keep colorful)
# Face error   : red          (status — keep colorful)
# Git branch   : green        (repo context — meaningful color)
# Git dirty    : orange (208) (repo context — meaningful color)
# User@host    : 245 (gray)   (static info — stays quiet)
# Directory    : default       (readable, no distraction)
# Separators   : 245 (gray)

# ── Build the prompt ──
setopt PROMPT_SUBST

# shellcheck disable=SC2034,SC2016
# PROMPT is a zsh special variable set by the user and read by zsh prompt expansion
# Single quotes are intentional: zsh performs prompt expansion (PROMPT_SUBST) at display time
PROMPT='%F{245}[%f${_prompt_face}%F{245}]%f ${vcs_info_msg_0_}${_prompt_untracked} %F{245}%n@%m%f %(5~|%-1~/.../%3~|%~)
%F{245}$%f '

# ── Right prompt (optional) ──
# Shows the time — uncomment if you want it
# RPROMPT='%F{245}%*%f'
