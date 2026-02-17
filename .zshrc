#!/bin/zsh
# ── Zsh Dotfiles ──
# Author: Shreyas Ugemuge
# Repo:   https://github.com/shreyas613/bash_old
# See:    CHANGELOG.md for release history

# ── Version ──
# Read from VERSION file relative to the real path of this .zshrc
# (follows symlinks back to the repo)
_zshrc_realpath="${${(%):-%x}:A}"
_zshrc_dir="${_zshrc_realpath:h}"
ZSH_DOTFILES_VERSION="$(cat "$_zshrc_dir/VERSION" 2>/dev/null || echo 'unknown')"
unset _zshrc_realpath _zshrc_dir

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
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ── Key bindings (emacs mode) ──
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ── Source local overrides (not tracked by git) ──
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── Version alias ──
alias dotfiles-version='echo "zsh-dotfiles v${ZSH_DOTFILES_VERSION}"'

# ── Startup benchmark ──
alias zsh-bench='time zsh -i -c exit'
