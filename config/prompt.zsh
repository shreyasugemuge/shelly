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

# ── Face indicator ──
# Captures the exit code of the previous command BEFORE anything
# else runs, then sets the face accordingly.
#
# We use a dedicated function added to precmd_functions so it
# plays nicely with anything else hooked into precmd.

_prompt_face=""

function _set_face() {
    if [[ $? -eq 0 ]]; then
        _prompt_face="%F{yellow}-_-%f"
    else
        _prompt_face="%F{red}O_O%f"
    fi
}

# ── Async git integration ──
# The old sync vcs_info + `git status --porcelain` pattern blocked the
# prompt for 10-30s in large/slow repos. Now a background worker computes
# the git segment, writes it to a tempfile, and signals us via SIGUSR1.
# On signal, we read the file and ask zle to repaint the prompt.

_prompt_git_info=""
_prompt_git_last_dir=""
_prompt_async_pid=0
_prompt_async_file="${TMPDIR:-/tmp}/shelly-prompt-git-$$"

# Worker — runs in a backgrounded subshell. Must be self-contained:
# no shared state with the parent except the tempfile + signal.
function _prompt_git_worker() {
    local dir=$1 parent=$2 outfile=$3
    builtin cd -q -- "$dir" 2>/dev/null || { : >|"$outfile"; kill -USR1 "$parent" 2>/dev/null; return; }

    # Bail fast if we're not inside a git work tree.
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        : >|"$outfile"
        kill -USR1 "$parent" 2>/dev/null
        return
    }

    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
        || branch=$(git rev-parse --short HEAD 2>/dev/null) \
        || branch="?"

    # Detached / rebase / merge state — mirrors vcs_info actionformats.
    local gitdir action=""
    gitdir=$(git rev-parse --git-dir 2>/dev/null)
    if [[ -n $gitdir ]]; then
        if   [[ -d $gitdir/rebase-merge || -d $gitdir/rebase-apply ]]; then action="|rebase"
        elif [[ -f $gitdir/MERGE_HEAD   ]]; then action="|merge"
        elif [[ -f $gitdir/CHERRY_PICK_HEAD ]]; then action="|cherry-pick"
        elif [[ -f $gitdir/BISECT_LOG   ]]; then action="|bisect"
        fi
    fi

    # Single porcelain call covers dirty, staged, and untracked.
    local status_out dirty="" staged="" untracked=""
    status_out=$(git status --porcelain=v1 2>/dev/null)
    if [[ -n $status_out ]]; then
        # X=index, Y=worktree. 2 chars + space + path.
        local line x y
        while IFS= read -r line; do
            x=${line[1]}
            y=${line[2]}
            [[ $x == '?' && $y == '?' ]] && { untracked="?"; continue; }
            [[ $x != ' ' && $x != '?' ]] && staged="+"
            [[ $y != ' ' && $y != '?' ]] && dirty="*"
            [[ -n $staged && -n $dirty && -n $untracked ]] && break
        done <<<"$status_out"
    fi

    local out="%F{green}(${branch}${action})%f"
    if [[ -n $dirty$staged$untracked ]]; then
        out+="%F{208}${dirty}${staged}${untracked}%f"
    fi

    printf '%s' "$out" >|"$outfile"
    kill -USR1 "$parent" 2>/dev/null
}

function _set_vcs_info() {
    local cur_dir=$PWD

    # Changed directory? Clear stale info immediately so we never paint the
    # wrong repo's branch while waiting for the worker.
    if [[ $cur_dir != $_prompt_git_last_dir ]]; then
        _prompt_git_info=""
        _prompt_git_last_dir=$cur_dir
    fi

    # Cancel any in-flight worker from the previous prompt.
    if (( _prompt_async_pid )) && kill -0 "$_prompt_async_pid" 2>/dev/null; then
        kill -TERM "$_prompt_async_pid" 2>/dev/null
    fi

    # Spawn detached worker. `&!` = background + disown so it never shows in jobs.
    _prompt_git_worker "$cur_dir" $$ "$_prompt_async_file" &!
    _prompt_async_pid=$!
}

# Signal handler: worker finished, read its output and repaint.
# zle reset-prompt is only valid while the line editor is active — the 2>/dev/null
# swallows the "widgets can only be called when ZLE is active" case.
function TRAPUSR1() {
    if [[ -r $_prompt_async_file ]]; then
        _prompt_git_info=$(<"$_prompt_async_file")
    fi
    _prompt_async_pid=0
    zle reset-prompt 2>/dev/null
}

# Hook both into precmd — face MUST come first to capture $?
# shellcheck disable=SC2034
# precmd_functions is a zsh special array called before each prompt; it IS used by zsh internals
precmd_functions=(_set_face _set_vcs_info)

# Cleanup the tempfile when the shell exits.
# shellcheck disable=SC2064
trap "rm -f '$_prompt_async_file' 2>/dev/null" EXIT

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
PROMPT='%F{245}[%f${_prompt_face}%F{245}]%f ${_prompt_git_info} %F{245}%n@%m%f %(5~|%-1~/.../%3~|%~)
%F{245}$%f '

# ── Right prompt (optional) ──
# Shows the time — uncomment if you want it
# RPROMPT='%F{245}%*%f'
