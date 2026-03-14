# ── Functions ──
# Author: Shreyas Ugemuge

# ── pan: Open man page as PDF in Preview (macOS) ──
function pan() {
    if [[ -z "$1" ]]; then
        echo "Usage: pan <command>"
        return 1
    fi
    if $IS_MACOS; then
        man -t "$1" | open -f -a /Applications/Preview.app
    else
        echo "pan: this function requires macOS Preview.app"
        echo "Try: man $1 | less"
        return 1
    fi
}

# ── mkcd: Create a directory and cd into it ──
function mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    # shellcheck disable=SC2164
    # mkcd's purpose is mkdir + cd atomically; if mkdir succeeds and cd fails, returning is correct
    mkdir -p "$1" && cd "$1"
}

# ── extract: Universal archive extractor ──
function extract() {
    if [[ ! -f "$1" ]]; then
        echo "extract: '$1' is not a valid file"
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1"   ;;
        *.tar.gz)  tar xzf "$1"   ;;
        *.tar.xz)  tar xJf "$1"   ;;
        *.bz2)     bunzip2 "$1"   ;;
        *.gz)      gunzip "$1"    ;;
        *.tar)     tar xf "$1"    ;;
        *.tbz2)    tar xjf "$1"   ;;
        *.tgz)     tar xzf "$1"   ;;
        *.zip)     unzip "$1"     ;;
        *.Z)       uncompress "$1";;
        *.7z)      7z x "$1"     ;;
        *.rar)     unrar x "$1"  ;;
        *)         echo "extract: unknown format '$1'" ;;
    esac
}

# ── whichip: Friendly display of all IPs ──
function whichip() {
    echo "Public IP : $(curl -s --max-time 3 ipinfo.io/ip)"
    if $IS_MACOS; then
        local _iface
        _iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
        echo "Local IP  : $(ipconfig getifaddr "${_iface:-en0}" 2>/dev/null || echo 'not connected')"
    else
        echo "Local IP  : $(hostname -I 2>/dev/null | awk '{print $1}' || echo 'not connected')"
    fi
}

# ── weather: Quick weather report ──
function weather() {
    local city="${1:-}"
    curl -s --max-time 3 "wttr.in/${city}?format=3"
}

# ── portfind: Find what's listening on a port ──
function portfind() {
    if [[ -z "$1" ]]; then
        echo "Usage: portfind <port>"
        return 1
    fi
    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "portfind: port must be a number (got: $1)"
        return 1
    fi
    if (( $1 < 1 || $1 > 65535 )); then
        echo "portfind: port must be 1-65535 (got: $1)"
        return 1
    fi
    lsof -i :"$1"
}

# ── ccnotify: iTerm2 notification when a command finishes ──
function ccnotify() {
    local msg="${*:-done}"
    if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        printf '\033]9;%s\007' "$msg"
    fi
}

# ── cc: Claude Code with completion notification ──
function cc() {
    claude "$@"
    ccnotify "Claude Code finished"
}

# ── iterm-setup: Install iTerm2 shell integration (run once) ──
function iterm-setup() {
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        echo "iterm-setup: not running in iTerm2"
        return 1
    fi
    local dest="${HOME}/.iterm2_shell_integration.zsh"
    echo "· Downloading iTerm2 shell integration…"
    curl -sL "https://iterm2.com/shell_integration/zsh" -o "$dest" && \
        echo "✓ Installed — restart your shell or run: source $dest" || \
        echo "✗ Download failed"
}

# ── devterm: Dynamic dev workspace ──

_IT2API_DEV="/Applications/iTerm.app/Contents/Resources/it2api"

# _dev_resize_layout: Resize all horizontal splits to 80% Claude / 20% terminal
# Walks the tab's split tree via iTerm2 Python API and calls async_update_layout()
_dev_resize_layout() {
    local anchor_sid="$1"
    python3 << PYEOF 2>/dev/null
import iterm2

async def main(connection):
    app = await iterm2.async_get_app(connection)
    tab = None
    for w in app.terminal_windows:
        for t in w.tabs:
            for s in t.sessions:
                if s.session_id == "${anchor_sid}":
                    tab = t
                    break
            if tab:
                break
        if tab:
            break
    if not tab:
        return

    def resize(node):
        if isinstance(node, iterm2.Session):
            return
        # Horizontal splitter = children stacked top-to-bottom
        if not node.vertical and len(node.children) == 2:
            top, bot = node.children[0], node.children[1]
            if isinstance(top, iterm2.Session) and isinstance(bot, iterm2.Session):
                total = top.grid_size.height + bot.grid_size.height
                top.preferred_size = iterm2.util.Size(
                    top.grid_size.width, int(total * 0.8))
                bot.preferred_size = iterm2.util.Size(
                    bot.grid_size.width, int(total * 0.2))
        for child in node.children:
            resize(child)

    resize(tab.root)
    await tab.async_update_layout()

iterm2.run_until_complete(main)
PYEOF
}

# _dev_state_file: Path to the file storing the primary session ID
_dev_state_file() {
    echo "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/devterm.session_id"
}

# _dev_persist_dir: Save DEVTMUX_DIR to ~/.zshrc.local (guards against duplicates)
_dev_persist_dir() {
    local dir="$1"
    local local_rc="$HOME/.zshrc.local"
    if [[ -f "$local_rc" ]] && grep -q 'DEVTMUX_DIR' "$local_rc"; then
        return 0
    fi
    echo "export DEVTMUX_DIR=\"${dir}\"" >> "$local_rc"
    echo -e "\033[0;90m·\033[0m Saved DEVTMUX_DIR to ~/.zshrc.local"
}

# _dev_get_code_dir: Discover code folder (env var, default, or prompt)
_dev_get_code_dir() {
    local dir="${DEVTMUX_DIR:-$HOME/code}"
    if [[ ! -d "$dir" ]]; then
        echo -e "\033[0;33m·\033[0m Code folder not found: $dir" >&2
        local input
        read -r "input?Enter path to your code folder: "
        dir="${input/#\~/$HOME}"
        if [[ ! -d "$dir" ]]; then
            echo -e "\033[0;31m✗\033[0m Directory does not exist: $dir" >&2
            return 1
        fi
        _dev_persist_dir "$dir"
        export DEVTMUX_DIR="$dir"
    fi
    echo "$dir"
}

# _dev_pick_projects: Interactive project picker (numbered list)
_dev_pick_projects() {
    local code_dir="$1"
    local names=()
    local branches=()

    for d in "$code_dir"/*/; do
        # Accept both .git dirs (normal repos) and .git files (worktrees)
        [[ -e "$d/.git" ]] || continue
        names+=("${d:t}")
        local branch="" wt_marker=""
        branch="$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
        [[ -f "$d/.git" ]] && wt_marker=" [wt]"
        branches+=("${branch}${wt_marker}")
    done

    if (( ${#names[@]} == 0 )); then
        echo -e "\033[0;31m✗\033[0m No git repos found in $code_dir. Set DEVTMUX_DIR to a different folder." >&2
        return 1
    fi

    echo "" >&2
    echo -e "  \033[1mdevterm\033[0m — pick 1-3 projects" >&2
    echo "" >&2
    for (( i=1; i<=${#names[@]}; i++ )); do
        printf "  \033[0;33m%2d\033[0m  %s \033[0;90m(%s)\033[0m\n" "$i" "${names[$i]}" "${branches[$i]}" >&2
    done
    echo "" >&2

    local input
    read -r "input?  Enter numbers (e.g. 1 3, add y suffix to yolo: 1y 3): "
    if [[ -z "$input" ]]; then
        echo -e "\033[0;31m✗\033[0m No projects selected" >&2
        return 1
    fi

    local selected=()
    for token in ${(s: :)input}; do
        local num="${token%%[yY]}"
        local yolo=""
        [[ "$token" =~ [yY]$ ]] && yolo=":yolo"
        if [[ ! "$num" =~ ^[0-9]+$ ]] || (( num < 1 || num > ${#names[@]} )); then
            echo -e "\033[0;33m·\033[0m Skipping invalid: $token" >&2
            continue
        fi
        selected+=("${names[$num]}${yolo}")
    done

    if (( ${#selected[@]} == 0 )); then
        echo -e "\033[0;31m✗\033[0m No valid projects selected" >&2
        return 1
    fi

    if (( ${#selected[@]} > 3 )); then
        echo -e "\033[0;33m·\033[0m Max 3 projects — using first 3" >&2
        selected=("${selected[@]:0:3}")
    fi

    printf '%s\n' "${selected[@]}"
}

# _dev_ensure_iterm2: Check running inside iTerm2 and Python module is available
_dev_ensure_iterm2() {
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m non-iTerm mode: devterm requires iTerm2 (current terminal: ${TERM_PROGRAM:-unknown})"
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

# _dev_window_exists: Check if the tracked devterm window is still open
_dev_window_exists() {
    local sid
    sid="$(cat "$(_dev_state_file)" 2>/dev/null)" || return 1
    [[ -n "$sid" ]] && "$_IT2API_DEV" show-hierarchy 2>/dev/null | grep -q "id=$sid"
}

# _dev_focus_window: Bring the devterm window to front
_dev_focus_window() {
    local sid
    sid="$(cat "$(_dev_state_file)" 2>/dev/null)" || return 1
    "$_IT2API_DEV" activate session "$sid" 2>/dev/null
    "$_IT2API_DEV" activate-app 2>/dev/null
}

# _dev_close_window: Close the devterm iTerm2 window
_dev_close_window() {
    local sid
    sid="$(cat "$(_dev_state_file)" 2>/dev/null)" || {
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m No devterm window tracked"
        return 0
    }
    local hierarchy cur_win="" win_id=""
    hierarchy=$("$_IT2API_DEV" show-hierarchy 2>/dev/null)
    while IFS= read -r line; do
        if [[ "$line" =~ 'Window id=([^ ]+)' ]]; then
            cur_win="${match[1]}"
        elif [[ "$line" == *"id=$sid"* ]]; then
            win_id="$cur_win"
            break
        fi
    done <<< "$hierarchy"

    rm -f "$(_dev_state_file)"
    if [[ -n "$win_id" ]]; then
        local win_num="${win_id#w}"
        osascript -e "tell application \"iTerm2\" to close window id $win_num" 2>/dev/null
        # shellcheck disable=SC2028
        echo "\033[0;32m✓\033[0m devterm window closed"
    else
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m devterm window already closed"
    fi
}

# _dev_build_session: Build the iTerm2 layout with one column per project
#
# Three-phase approach:
#   Phase 1 — Create all splits and navigate panes to project dirs
#   Phase 2 — Resize horizontal splits to 80% Claude / 20% terminal
#   Phase 3 — Clear scrollback on all panes and launch Claude
_dev_build_session() {
    # Split args on -- separator: projects before, yolo_flags after
    local projects=()
    local yolo_flags=()
    local past_sep=0
    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            past_sep=1
            continue
        fi
        if (( past_sep )); then
            yolo_flags+=("$arg")
        else
            projects+=("$arg")
        fi
    done
    local code_dir="${DEVTMUX_DIR:-$HOME/code}"
    local count=${#projects[@]}

    _dev_ensure_iterm2 || return 1

    # Clean up any tracked window before creating a new one
    if [[ -f "$(_dev_state_file)" ]]; then
        _dev_close_window >/dev/null 2>&1
    fi

    # Create first tab (new iTerm2 window)
    local output session_id
    output=$("$_IT2API_DEV" create-tab 2>/dev/null) || {
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Failed to create iTerm2 window"
        echo "  Is Python API enabled? iTerm2 → Preferences → General → Magic → Enable Python API"
        return 1
    }
    session_id=${${(M)${=output}:#id=*}#id=}
    if [[ -z "$session_id" ]]; then
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Could not parse session ID from it2api output"
        return 1
    fi

    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    echo "$session_id" > "$(_dev_state_file)"

    # Track pane session IDs
    local top_sessions=("$session_id")
    local term_sessions=()

    # Create additional columns (vertical splits off the last top pane)
    local last_top="$session_id"
    local col_out="" col_sid=""
    for (( i=2; i<=count; i++ )); do
        col_out=$("$_IT2API_DEV" split-pane "$last_top" --vertical 2>/dev/null)
        col_sid=${${(M)${=col_out}:#id=*}#id=}
        if [[ -z "$col_sid" ]]; then
            echo -e "\033[0;33m·\033[0m Warning: failed to create column $i — continuing with $(( i - 1 )) columns" >&2
            count=$(( i - 1 ))
            break
        fi
        top_sessions+=("$col_sid")
        last_top="$col_sid"
    done

    # ── Phase 1: Create horizontal splits and navigate all panes ──
    local term_out="" term_sid=""
    for (( i=1; i<=count; i++ )); do
        local top="${top_sessions[$i]}"
        local proj_dir="$code_dir/${projects[$i]}"

        # Navigate top pane to project dir and clear
        "$_IT2API_DEV" send-text "$top" "cd ${(q)proj_dir} && clear"$'\n' 2>/dev/null

        # Split horizontally for terminal pane (below)
        term_out=$("$_IT2API_DEV" split-pane "$top" 2>/dev/null)
        term_sid=${${(M)${=term_out}:#id=*}#id=}
        term_sessions+=("$term_sid")

        # Navigate terminal pane to project dir and clear
        "$_IT2API_DEV" send-text "$term_sid" "cd ${(q)proj_dir} && clear"$'\n' 2>/dev/null
    done

    # ── Phase 2: Resize all horizontal splits to 80/20 ──
    sleep 0.5
    _dev_resize_layout "${top_sessions[1]}"

    # ── Phase 3: Clear scrollback and launch Claude ──
    for (( i=1; i<=count; i++ )); do
        local top="${top_sessions[$i]}"
        local term="${term_sessions[$i]}"
        local proj="${projects[$i]}"
        local claude_cmd="claude"
        if (( ${yolo_flags[$i]:-0} )); then
            claude_cmd="claude --dangerously-skip-permissions"
        fi

        # Clear scrollback on both panes (removes cd/clear from history)
        "$_IT2API_DEV" inject "$top" $'\033]1337;ClearScrollback\007' 2>/dev/null
        "$_IT2API_DEV" inject "$term" $'\033]1337;ClearScrollback\007' 2>/dev/null

        # Set pane titles via inject, then lock Claude pane so it can't override
        local yolo_prefix=""
        (( ${yolo_flags[$i]:-0} )) && yolo_prefix=$'\xe2\x9a\xa1 '
        "$_IT2API_DEV" inject "$top" "$(printf '\033]0;%sclaude :: %s\007' "$yolo_prefix" "$proj")" 2>/dev/null
        "$_IT2API_DEV" set-profile-property "$top" allow_title_setting false 2>/dev/null
        "$_IT2API_DEV" inject "$term" "$(printf '\033]0;terminal :: %s\007' "$proj")" 2>/dev/null

        # Launch Claude in top pane
        "$_IT2API_DEV" send-text "$top" "$claude_cmd"$'\n' 2>/dev/null
    done

    # Focus first top pane
    "$_IT2API_DEV" activate session "${top_sessions[1]}" 2>/dev/null
    "$_IT2API_DEV" activate-app 2>/dev/null
}

# _dev_launch: Orchestrate code folder discovery, picker, and session build
_dev_launch() {
    local code_dir
    code_dir="$(_dev_get_code_dir)" || return 1

    local projects_raw
    projects_raw="$(_dev_pick_projects "$code_dir")" || return 1

    local projects=()
    local yolo_flags=()
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ "$line" == *":yolo" ]]; then
            projects+=("${line%:yolo}")
            yolo_flags+=(1)
        else
            projects+=("$line")
            yolo_flags+=(0)
        fi
    done <<< "$projects_raw"

    _dev_build_session "${projects[@]}" -- "${yolo_flags[@]}"
}

# devterm: Entry point
function devterm() {
    case "${1:-}" in
        kill|stop)
            _dev_close_window
            ;;
        status|info)
            echo ""
            if _dev_window_exists; then
                echo -e "  \033[0;32m✓\033[0m devterm window open"
            else
                echo -e "  \033[0;90m·\033[0m No devterm window open"
            fi
            echo ""
            ;;
        help|-h|--help)
            echo ""
            echo "  devterm           launch the dev workspace (interactive project picker)"
            echo "  devterm kill      close the iTerm2 window"
            echo "  devterm status    check window state"
            echo "  devterm help      show this message"
            echo ""
            echo "  Workspace layout:"
            echo "    1-3 projects    select from git repos in your code folder"
            echo "    add y suffix    skip permissions mode (e.g. 1y 3)"
            echo "    top pane        Claude Code"
            echo "    bottom pane     terminal with project name banner"
            echo ""
            echo "  Requires iTerm2 with Python API enabled:"
            echo "    Preferences → General → Magic → Enable Python API"
            echo ""
            ;;
        *)
            _dev_ensure_iterm2 || return 1
            if _dev_window_exists; then
                local choice
                read -r "choice?devterm window exists. [f]ocus or [k]ill and start fresh? "
                case "$choice" in
                    k|K)
                        _dev_close_window
                        _dev_launch
                        ;;
                    *)
                        _dev_focus_window
                        ;;
                esac
            else
                _dev_launch
            fi
            ;;
    esac
}

# Deprecation shim — forwards old name to devterm
function devtmux() {
    echo "devtmux is now 'devterm'. Redirecting…"
    devterm "$@"
}

# ── Tab completion for devterm ──
_dev_completion() {
    # shellcheck disable=SC2034
    # subcmds is consumed by _describe, which shellcheck cannot trace
    local -a subcmds=(
        'kill:close the devterm window'
        'stop:close the devterm window'
        'status:show window state'
        'info:show window state'
        'help:show usage reference'
    )
    _describe 'devterm command' subcmds
}
# compdef registration moved to .zshrc (after compinit)
