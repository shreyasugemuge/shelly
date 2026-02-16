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

function _set_vcs_info() {
    vcs_info
}

# Hook both into precmd — face MUST come first to capture $?
precmd_functions=(_set_face _set_vcs_info)

# ── Color reference ──
# Face success : yellow
# Face error   : red
# Git branch   : green
# Git dirty    : orange (208)
# User         : magenta
# Host         : 117 (light blue)
# Directory    : cyan
# Separators   : 245 (gray)

# ── Build the prompt ──
setopt PROMPT_SUBST

PROMPT='%F{245}[%f${_prompt_face}%F{245}]%f ${vcs_info_msg_0_} %F{magenta}%n%f%F{245}@%f%F{117}%m%f %F{cyan}%~%f
%F{245}$%f '

# ── Right prompt (optional) ──
# Shows the time — uncomment if you want it
# RPROMPT='%F{245}%*%f'
