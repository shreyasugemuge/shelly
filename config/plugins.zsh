# ── Plugins ──
# Author: Shreyas Ugemuge
#
# Lightweight plugin loading — no framework needed.
# Currently: fzf (shell integration), zsh-syntax-highlighting
#
# Search order: Homebrew → /usr/share (apt/dnf) → /usr/local/share

# ── Find plugin directories ──
_plugin_dirs=()
_brew_share="$(brew --prefix 2>/dev/null)/share"
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

# ── fzf shell integration ──
# Enables Ctrl-T (files), Ctrl-R (history), Alt-C (cd) keybindings
if command -v fzf &>/dev/null; then
    # shellcheck disable=SC1090
    # fzf --zsh outputs shell code for key bindings and completion
    source <(fzf --zsh)
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
