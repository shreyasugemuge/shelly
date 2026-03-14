# ── Plugins ──
# Author: Shreyas Ugemuge
#
# Lightweight plugin loading — no framework needed.
# Currently: zsh-autosuggestions, zsh-syntax-highlighting
#
# Search order: Homebrew → /usr/share (apt/dnf) → /usr/local/share

# ── Find plugin directories ──
_plugin_dirs=()
_brew_share="${_SHELLY_BREW_PREFIX}/share"
[[ -d "$_brew_share" ]] && _plugin_dirs+=("$_brew_share")
[[ -d /usr/share ]] && _plugin_dirs+=(/usr/share)
[[ -d /usr/local/share ]] && _plugin_dirs+=(/usr/local/share)

_find_plugin() {
    local plugin="$1"
    for _dir in "${_plugin_dirs[@]}"; do
        if [[ -f "$_dir/$plugin/$plugin.zsh" ]]; then
            echo "$_dir/$plugin/$plugin.zsh"
            return 0
        fi
    done
    return 1
}

# ── zsh-autosuggestions ──
# Fish-style ghost-text suggestions from history as you type.
# Accept with → (right arrow) or End. Partial accept with Alt-→ (word).
_as_path="$(_find_plugin zsh-autosuggestions)"
if [[ -n "$_as_path" ]]; then
    # shellcheck disable=SC1090
    # Dynamic path: _as_path is resolved above by _find_plugin searching known directories
    source "$_as_path"
    # shellcheck disable=SC2034
    # ZSH_AUTOSUGGEST_* are read by zsh-autosuggestions internals, not by our code
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_USE_ASYNC=1
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
fi
unset _as_path

# ── iTerm2 Shell Integration ──
# Enables command marks (Cmd+Shift+↑/↓), semantic history, recent dirs (Cmd+Opt+/).
# Source if present; run `iterm-setup` once to install.
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    _iterm_si="${HOME}/.iterm2_shell_integration.zsh"
    # shellcheck disable=SC1090
    # Dynamic path: sourced only when file exists (installed via iterm-setup)
    [[ -f "$_iterm_si" ]] && source "$_iterm_si"
    unset _iterm_si
fi

# ── SOURCING ORDER GUARD ──────────────────────────────────────────────
# zsh-syntax-highlighting MUST be the last plugin sourced in this file.
# It wraps ZLE widgets at source time; sourcing anything after it
# silently breaks those widgets (completions, history search, etc.).
# DO NOT add any plugin source lines below this guard.
# See: https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlighting-be-sourced-at-the-end
# ─────────────────────────────────────────────────────────────────────

# ── zsh-syntax-highlighting ──
# Colors commands as you type: green = valid, red = not found.
# MUST be sourced last (after all other plugins and widgets).
_sh_path="$(_find_plugin zsh-syntax-highlighting)"
if [[ -n "$_sh_path" ]]; then
    # shellcheck disable=SC1090
    # Dynamic path: _sh_path is resolved above by _find_plugin searching known directories
    source "$_sh_path"
fi
unset _sh_path

unset _brew_share _plugin_dirs
unfunction _find_plugin 2>/dev/null
