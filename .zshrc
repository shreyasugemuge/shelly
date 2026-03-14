#!/bin/zsh
# ── Shelly ──
# A modular zsh configuration by Shreyas Ugemuge
# Repo: https://github.com/shreyasugemuge/shelly
# See:  CHANGELOG.md for release history

# ── Version ──
# Read from VERSION file relative to the real path of this .zshrc
# (follows symlinks back to the repo)
_zshrc_realpath="${${(%):-%x}:A}"
_zshrc_dir="${_zshrc_realpath:h}"
ZSH_DOTFILES_VERSION="$(cat "$_zshrc_dir/VERSION" 2>/dev/null || echo 'unknown')"
unset _zshrc_realpath _zshrc_dir

# ── Platform Detection ──
# Set once here, used in all sourced modules.
[[ "$OSTYPE" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
[[ "$OSTYPE" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false

# ── Directory where config modules live ──
ZDOTDIR_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# ── Source modular configs ──
# Order matters: deps first (auto-installs missing packages),
# then environment, prompt, aliases, functions, plugins, sysinfo last
for config_file in \
    "$ZDOTDIR_CUSTOM/deps.zsh" \
    "$ZDOTDIR_CUSTOM/environment.zsh" \
    "$ZDOTDIR_CUSTOM/prompt.zsh" \
    "$ZDOTDIR_CUSTOM/aliases.zsh" \
    "$ZDOTDIR_CUSTOM/functions.zsh" \
    "$ZDOTDIR_CUSTOM/plugins.zsh" \
    "$ZDOTDIR_CUSTOM/monitor.zsh" \
    "$ZDOTDIR_CUSTOM/sysinfo.zsh"; do
    [[ -f "$config_file" ]] && source "$config_file"
done
unset config_file

# ── History ──
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# ── Completion (cached — regenerate once per day) ──
# Add zsh-completions to fpath if installed (extra completions for brew, docker, git, etc.)
_brew_prefix="$(brew --prefix 2>/dev/null)"
if [[ -d "$_brew_prefix/share/zsh-completions" ]]; then
    fpath=("$_brew_prefix/share/zsh-completions" $fpath)
fi
unset _brew_prefix
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"
if [[ -f "$_zcompdump" && $(date +'%j') == $(stat -f '%Sm' -t '%j' "$_zcompdump" 2>/dev/null || date -r "$_zcompdump" +'%j' 2>/dev/null) ]]; then
    compinit -C -d "$_zcompdump"
else
    compinit -d "$_zcompdump"
fi
unset _zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:messages' format '%F{purple}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}── no matches ──%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,comm -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# ── fzf-tab (must load after compinit) ──
_fzf_tab_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/fzf-tab"
if [[ -f "$_fzf_tab_dir/fzf-tab.plugin.zsh" ]]; then
    # shellcheck disable=SC1091
    # fzf-tab is cloned by deps.zsh; path is known and stable
    source "$_fzf_tab_dir/fzf-tab.plugin.zsh"
    # Preview files/directories during completion
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
    zstyle ':fzf-tab:complete:ls:*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
    zstyle ':fzf-tab:*' fzf-flags --height=40% --reverse
    zstyle ':fzf-tab:*' switch-group ',' '.'
fi
unset _fzf_tab_dir

# ── Key bindings (emacs mode) ──
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ── Source local overrides (not tracked by git) ──
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── Version alias ──
alias shelly-version='echo "shelly v${ZSH_DOTFILES_VERSION}"'

# ── Startup benchmark ──
alias zsh-bench='time zsh -i -c exit'
