#!/bin/zsh
# ── Shelly ──
# A modular zsh configuration by Shreyas Ugemuge
# Repo: https://github.com/shreyasugemuge/shelly
# See:  CHANGELOG.md for release history

# ── Version ──
# Read from VERSION file installed alongside config modules
ZSH_DOTFILES_VERSION="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/VERSION" 2>/dev/null || echo 'unknown')"

# ── Platform Detection ──
# Set once here, used in all sourced modules.
[[ "$OSTYPE" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
[[ "$OSTYPE" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false

# ── Brew prefix (computed once, reused by modules and completion) ──
_SHELLY_BREW_PREFIX="$(brew --prefix 2>/dev/null)"

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
    "$ZDOTDIR_CUSTOM/iterm2.zsh" \
    "$ZDOTDIR_CUSTOM/functions.zsh" \
    "$ZDOTDIR_CUSTOM/release.zsh" \
    "$ZDOTDIR_CUSTOM/devterm.zsh" \
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
if [[ -d "$_SHELLY_BREW_PREFIX/share/zsh-completions" ]]; then
    fpath=("$_SHELLY_BREW_PREFIX/share/zsh-completions" $fpath)
fi
unset _SHELLY_BREW_PREFIX
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"
if [[ -f "$_zcompdump" && $(date +'%j') == $(stat -f '%Sm' -t '%j' "$_zcompdump" 2>/dev/null || date -r "$_zcompdump" +'%j' 2>/dev/null) ]]; then
    compinit -u -C -d "$_zcompdump"
else
    compinit -u -d "$_zcompdump"
    touch "$_zcompdump"
fi
unset _zcompdump
zstyle ':completion:*' menu select
# Match strategy (tried in order, stops at first match):
#   1. Case-insensitive
#   2. Partial-word at separators (._-)
#   3. Substring anywhere
#   4. Approximate (allow 1 typo)
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*' \
    'm:{a-zA-Z}={A-Za-z} r:|?=**'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:messages' format '%F{purple}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}── no matches ──%f'
zstyle ':completion:*:corrections' format '%F{green}── %d (errors: %e) ──%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,comm -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
# Show recently modified files first for file completion
zstyle ':completion:*' file-sort modification
# cd: never offer the current directory, show parent (..) first
zstyle ':completion:*:cd:*' ignore-parents parent pwd
# Smarter directory completion: complete in-place before cycling
zstyle ':completion:*' insert-tab pending
# Deduplicate: don't offer a match that's already on the command line
zstyle ':completion:*:(rm|cp|mv|kill|diff):*' ignore-line other
# ssh/scp/rsync: complete hosts from known_hosts and config
zstyle ':completion:*:(ssh|scp|rsync):*' hosts \
    ${${${(f)"$(cat ~/.ssh/known_hosts 2>/dev/null)"}%%[# ]*}%%,*} \
    ${${${(M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*[*?]*}

# ── Register completions (must be after compinit) ──
(( $+functions[_dev_completion] )) && compdef _dev_completion devterm
(( $+functions[_dev_completion] )) && compdef _dev_completion devtmux
(( $+functions[_sysmon_completion] )) && compdef _sysmon_completion sysmon

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

