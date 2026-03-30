# ── iTerm2 Utilities ──
# Author: Shreyas Ugemuge
#
# Shared utilities for iTerm2 tab/session management.
# Used by: devterm.zsh, monitor.zsh
# Requires: iTerm2 with Python API enabled

# Configurable: override SHELLY_IT2API in ~/.zshrc.local to use a custom path
: "${SHELLY_IT2API:=/Applications/iTerm.app/Contents/Resources/it2api}"
_SHELLY_IT2API="$SHELLY_IT2API"

# ── Ensure running inside iTerm2 and Python module is available ──
_iterm2_ensure() {
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        local caller="${1:-feature}"
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m non-iTerm mode: $caller requires iTerm2 (current terminal: ${TERM_PROGRAM:-unknown})"
        return 1
    fi
    if ! python3 -c "import iterm2" 2>/dev/null; then
        # shellcheck disable=SC2028
        echo "\033[0;33m·\033[0m Installing Python iterm2 module…"
        pip3 install iterm2 --quiet || {
            # shellcheck disable=SC2028
            echo "\033[0;31m✗\033[0m Failed to install iterm2 module. Run: pip3 install iterm2"
            return 1
        }
    fi
}

# ── Check if a tracked tab is still open ──
# Usage: _iterm2_tab_exists "$(state_file_fn)"
_iterm2_tab_exists() {
    local state_file="$1"
    local sid=""
    sid="$(cat "$state_file" 2>/dev/null)" || return 1
    [[ -n "$sid" ]] && "$_SHELLY_IT2API" show-hierarchy 2>/dev/null | grep -q "id=$sid"
}

# ── Bring a tracked tab to front ──
# Usage: _iterm2_focus_tab "$(state_file_fn)"
_iterm2_focus_tab() {
    local state_file="$1"
    local sid=""
    sid="$(cat "$state_file" 2>/dev/null)" || return 1
    "$_SHELLY_IT2API" activate session "$sid" 2>/dev/null
    "$_SHELLY_IT2API" activate-app 2>/dev/null
}

# ── Close a tracked tab ──
# Usage: _iterm2_close_tab "$(state_file_fn)" "label" ["dim_state_file"]
# When dim_state_file is provided, restores the dim-inactive-panes preference.
_iterm2_close_tab() {
    local state_file="$1"
    local label="$2"
    local dim_state_file="${3:-}"

    local sid=""
    sid="$(cat "$state_file" 2>/dev/null)" || {
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m No $label tab tracked"
        return 0
    }

    # Find window and tab ID containing this session
    local hierarchy="" cur_win="" cur_tab="" win_id="" tab_id=""
    hierarchy=$("$_SHELLY_IT2API" show-hierarchy 2>/dev/null)
    while IFS= read -r line; do
        if [[ "$line" =~ 'Window id=([^ ]+)' ]]; then
            cur_win="${match[1]}"
        elif [[ "$line" =~ 'Tab id=([^ ]+)' ]]; then
            cur_tab="${match[1]}"
        elif [[ "$line" == *"id=$sid"* ]]; then
            win_id="$cur_win"
            tab_id="$cur_tab"
            break
        fi
    done <<< "$hierarchy"

    # Restore dimming preference if saved
    if [[ -n "$dim_state_file" && -f "$dim_state_file" ]]; then
        local prev_dim=""
        prev_dim=$(cat "$dim_state_file" 2>/dev/null)
        if [[ "$prev_dim" == "1" ]]; then
            defaults write com.googlecode.iterm2 DimInactiveSplitPanes -bool true
        fi
        rm -f "$dim_state_file"
    fi

    rm -f "$state_file"
    if [[ -n "$win_id" && -n "$tab_id" ]]; then
        local win_num="${win_id#w}"
        local tab_num="${tab_id#t}"
        osascript -e "tell application \"iTerm2\" to close (first tab of window id $win_num whose id = $tab_num)" 2>/dev/null
        # shellcheck disable=SC2028
        echo "\033[0;32m✓\033[0m $label tab closed"
    else
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m $label tab already closed"
    fi
}
