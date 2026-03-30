# ── Dev Workspace ──
# Author: Shreyas Ugemuge
#
# Dynamic dev workspace — launches iTerm2 tabs with Claude Code + terminal panes.
# Depends on: iterm2.zsh ($_SHELLY_IT2API, _iterm2_* functions)
#
# Usage:
#   devterm              — pick projects, launch workspace
#   devterm -s           — split mode (single project, multi-Claude grid)
#   devterm -s -c        — split mode in current directory
#   devterm kill         — close workspace tab
#   devterm config       — show/change code directory
#   devterm help         — full usage reference

# ── Configurable defaults (override in ~/.zshrc.local) ──
# Layout split ratio for Claude (top) vs terminal (bottom) panes
: "${SHELLY_DEVTERM_RATIO:=0.8}"
# Directory names to search under $HOME when auto-detecting code folder
(( ${#SHELLY_CODE_DIRS[@]} )) || SHELLY_CODE_DIRS=("code" "projects" "dev" "src" "repos" "workspace" "work")

# _dev_resize_layout: Resize all horizontal splits to Claude / terminal ratio
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
                    top.grid_size.width, int(total * ${SHELLY_DEVTERM_RATIO}))
                bot.preferred_size = iterm2.util.Size(
                    bot.grid_size.width, int(total * (1.0 - ${SHELLY_DEVTERM_RATIO})))
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

# _dev_persist_dir: Save or update DEVTMUX_DIR in ~/.zshrc.local
_dev_persist_dir() {
    local dir="$1"
    local local_rc="$HOME/.zshrc.local"
    if [[ -f "$local_rc" ]] && grep -q 'DEVTMUX_DIR' "$local_rc"; then
        sed -i '' "s|^export DEVTMUX_DIR=.*|export DEVTMUX_DIR=\"${dir}\"|" "$local_rc"
    else
        echo "export DEVTMUX_DIR=\"${dir}\"" >> "$local_rc"
    fi
    # shellcheck disable=SC2028
    echo "\033[0;90m·\033[0m Saved DEVTMUX_DIR to ~/.zshrc.local"
}

# _dev_unpersist_dir: Remove DEVTMUX_DIR from ~/.zshrc.local
_dev_unpersist_dir() {
    local local_rc="$HOME/.zshrc.local"
    if [[ -f "$local_rc" ]] && grep -q 'DEVTMUX_DIR' "$local_rc"; then
        sed -i '' '/^export DEVTMUX_DIR=/d' "$local_rc"
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m Removed DEVTMUX_DIR from ~/.zshrc.local"
    fi
    unset DEVTMUX_DIR
}

# _dev_pick_code_dir: Interactive directory picker for code folder
_dev_pick_code_dir() {
    local candidates=()
    local candidate_labels=()

    # Check common directory names (configurable via SHELLY_CODE_DIRS)
    for name in "${SHELLY_CODE_DIRS[@]}"; do
        local path="$HOME/$name"
        if [[ -d "$path" ]]; then
            # Count git repos inside
            local count=0
            for d in "$path"/*/; do
                [[ -e "$d/.git" ]] && (( count++ ))
            done
            if (( count > 0 )); then
                candidates+=("$path")
                # shellcheck disable=SC2088
                candidate_labels+=("~/$name \033[0;90m($count repos)\033[0m")
            fi
        fi
    done

    echo "" >&2
    echo -e "  \033[1mdevterm\033[0m — pick your code directory" >&2
    echo "" >&2

    if (( ${#candidates[@]} > 0 )); then
        for (( i=1; i<=${#candidates[@]}; i++ )); do
            printf "  \033[0;33m%2d\033[0m  %b\n" "$i" "${candidate_labels[$i]}" >&2
        done
        echo "" >&2
        printf "  \033[0;33m c\033[0m  enter a custom path\n" >&2
        echo "" >&2

        local input=""
        read -r "input?  Enter choice: "

        if [[ "$input" == "c" || "$input" == "C" ]]; then
            local custom=""
            read -r "custom?  Enter path: "
            custom="${custom/#\~/$HOME}"
            if [[ ! -d "$custom" ]]; then
                echo -e "\033[0;31m✗\033[0m Directory does not exist: $custom" >&2
                return 1
            fi
            echo "$custom"
            return 0
        fi

        if [[ -z "$input" || ! "$input" =~ ^[0-9]+$ ]] || (( input < 1 || input > ${#candidates[@]} )); then
            echo -e "\033[0;31m✗\033[0m Invalid selection" >&2
            return 1
        fi
        echo "${candidates[$input]}"
    else
        echo -e "  \033[0;90mNo common code directories found\033[0m" >&2
        echo "" >&2
        local custom=""
        read -r "custom?  Enter path to your code folder: "
        custom="${custom/#\~/$HOME}"
        if [[ ! -d "$custom" ]]; then
            echo -e "\033[0;31m✗\033[0m Directory does not exist: $custom" >&2
            return 1
        fi
        echo "$custom"
    fi
}

# _dev_get_code_dir: Discover code folder (env var, default, or prompt)
_dev_get_code_dir() {
    # If explicitly configured, use it
    if [[ -n "${DEVTMUX_DIR:-}" && -d "$DEVTMUX_DIR" ]]; then
        echo "$DEVTMUX_DIR"
        return 0
    fi

    # If default ~/code exists, use it
    if [[ -d "$HOME/code" ]]; then
        echo "$HOME/code"
        return 0
    fi

    # If DEVTMUX_DIR was set but doesn't exist, warn
    if [[ -n "${DEVTMUX_DIR:-}" ]]; then
        echo -e "\033[0;33m·\033[0m Configured code folder not found: $DEVTMUX_DIR" >&2
    fi

    # Interactive picker
    local dir=""
    dir="$(_dev_pick_code_dir)" || return 1
    _dev_persist_dir "$dir"
    export DEVTMUX_DIR="$dir"
    echo "$dir"
}

# _dev_config: Show or change the devterm code directory
_dev_config() {
    case "${1:-}" in
        reset)
            _dev_unpersist_dir
            # shellcheck disable=SC2028
            echo "\033[0;32m✓\033[0m devterm directory reset to default (~/$( [[ -d "$HOME/code" ]] && echo "code" || echo "auto-detect" ))"
            echo "  Run 'devterm' to pick a new directory."
            ;;
        *)
            local current="${DEVTMUX_DIR:-$HOME/code}"
            echo ""
            if [[ -n "${DEVTMUX_DIR:-}" ]]; then
                echo -e "  \033[1mCode directory:\033[0m $current \033[0;90m(configured)\033[0m"
            elif [[ -d "$HOME/code" ]]; then
                echo -e "  \033[1mCode directory:\033[0m $current \033[0;90m(default)\033[0m"
            else
                echo -e "  \033[1mCode directory:\033[0m \033[0;90mnot configured\033[0m"
            fi

            if [[ -d "$current" ]]; then
                local count=0
                for d in "$current"/*/; do
                    [[ -e "$d/.git" ]] && (( count++ ))
                done
                echo -e "  \033[0;90m$count repos found\033[0m"
            fi
            echo ""

            local choice=""
            read -r "choice?  [k]eep or [c]hange? "
            case "$choice" in
                c|C)
                    local dir=""
                    dir="$(_dev_pick_code_dir)" || return 1
                    _dev_persist_dir "$dir"
                    export DEVTMUX_DIR="$dir"
                    # shellcheck disable=SC2028
                    echo "\033[0;32m✓\033[0m Code directory set to $dir"
                    ;;
                *)
                    echo -e "  \033[0;90m·\033[0m No changes"
                    ;;
            esac
            ;;
    esac
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
_dev_ensure_iterm2() { _iterm2_ensure "devterm"; }

# _dev_tab_exists: Check if the tracked devterm tab is still open
_dev_tab_exists() { _iterm2_tab_exists "$(_dev_state_file)"; }

# _dev_focus_tab: Bring the devterm tab to front
_dev_focus_tab() { _iterm2_focus_tab "$(_dev_state_file)"; }

# _dev_close_tab: Close the devterm iTerm2 tab
_dev_close_tab() { _iterm2_close_tab "$(_dev_state_file)" "devterm"; }

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

    # Clean up any tracked tab before creating a new one
    if [[ -f "$(_dev_state_file)" ]]; then
        _dev_close_tab >/dev/null 2>&1
    fi

    # Get current window ID so we create a tab, not a new window
    local current_window
    current_window=$("$_SHELLY_IT2API" show-focus 2>/dev/null | awk '/^Key window:/{print $3}')

    # Create new tab in the current iTerm2 window
    local output session_id
    output=$("$_SHELLY_IT2API" create-tab --window "$current_window" 2>/dev/null) || {
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Failed to create iTerm2 tab"
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
        col_out=$("$_SHELLY_IT2API" split-pane "$last_top" --vertical 2>/dev/null)
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
        "$_SHELLY_IT2API" send-text "$top" "cd ${(q)proj_dir} && clear"$'\n' 2>/dev/null

        # Split horizontally for terminal pane (below)
        term_out=$("$_SHELLY_IT2API" split-pane "$top" 2>/dev/null)
        term_sid=${${(M)${=term_out}:#id=*}#id=}
        term_sessions+=("$term_sid")

        # Navigate terminal pane to project dir and clear
        "$_SHELLY_IT2API" send-text "$term_sid" "cd ${(q)proj_dir} && clear"$'\n' 2>/dev/null
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
        "$_SHELLY_IT2API" inject "$top" $'\033]1337;ClearScrollback\007' 2>/dev/null
        "$_SHELLY_IT2API" inject "$term" $'\033]1337;ClearScrollback\007' 2>/dev/null

        # Set pane titles via inject, then lock Claude pane so it can't override
        local yolo_prefix=""
        (( ${yolo_flags[$i]:-0} )) && yolo_prefix=$'\xe2\x9a\xa1 '
        "$_SHELLY_IT2API" inject "$top" "$(printf '\033]0;%sclaude :: %s\007' "$yolo_prefix" "$proj")" 2>/dev/null
        "$_SHELLY_IT2API" set-profile-property "$top" allow_title_setting false 2>/dev/null
        "$_SHELLY_IT2API" inject "$term" "$(printf '\033]0;terminal :: %s\007' "$proj")" 2>/dev/null

        # Launch Claude in top pane
        "$_SHELLY_IT2API" send-text "$top" "$claude_cmd"$'\n' 2>/dev/null
    done

    # Focus first top pane
    "$_SHELLY_IT2API" activate session "${top_sessions[1]}" 2>/dev/null
    "$_SHELLY_IT2API" activate-app 2>/dev/null
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
            _dev_close_tab
            ;;
        status|info)
            echo ""
            if _dev_tab_exists; then
                echo -e "  \033[0;32m✓\033[0m devterm tab open"
            else
                echo -e "  \033[0;90m·\033[0m No devterm tab open"
            fi
            echo ""
            ;;
        config)
            shift
            _dev_config "${1:-}"
            ;;
        help|-h|--help)
            echo ""
            echo "  devterm              launch the dev workspace (interactive project picker)"
            echo "  devterm kill         close the devterm tab"
            echo "  devterm status       check tab state"
            echo "  devterm config       show or change the code directory"
            echo "  devterm config reset reset to default (auto-detect)"
            echo "  devterm help         show this message"
            echo ""
            echo "  devterm -s           split mode — multiple Claude panes in a grid"
            echo "  devterm -s -c        split mode in the current directory"
            echo "  devterm -s kill      close the split tab"
            echo "  devterm -s status    check split tab state"
            echo "  devterm -s help      show split mode help"
            echo ""
            echo "  Workspace layout:"
            echo "    1-3 projects    select from git repos in your code folder"
            echo "    add y suffix    skip permissions mode (e.g. 1y 3)"
            echo "    top pane        Claude Code"
            echo "    bottom pane     terminal with project name banner"
            echo ""
            echo "  Split mode layout (1-8 panes):"
            echo "    1→full  2→[2]  3→[3]  4→[2×2]  5→[2+2+1]"
            echo "    6→[3×3]  7→[3+3+1]  8→[4×4]"
            echo ""
            echo "  Requires iTerm2 with Python API enabled:"
            echo "    Preferences → General → Magic → Enable Python API"
            echo ""
            ;;
        -s)
            shift
            # Check for -c flag
            local split_cwd=false
            if [[ "${1:-}" == "-c" ]]; then
                split_cwd=true
                shift
            fi
            case "${1:-}" in
                kill|stop)
                    _dev_split_close_tab
                    ;;
                status|info)
                    echo ""
                    if _dev_split_tab_exists; then
                        echo -e "  \033[0;32m✓\033[0m devterm split tab open"
                    else
                        echo -e "  \033[0;90m·\033[0m No devterm split tab open"
                    fi
                    echo ""
                    ;;
                help|-h|--help)
                    echo ""
                    echo "  devterm -s            launch split mode (single project, multiple Claude panes)"
                    echo "  devterm -s -c         split mode in the current directory (skip project picker)"
                    echo "  devterm -s kill       close the split tab"
                    echo "  devterm -s status     check split tab state"
                    echo "  devterm -s help       show this message"
                    echo ""
                    echo "  Grid layouts (1-8 panes):"
                    echo "    1→full  2→[2]  3→[3]  4→[2×2]  5→[2+2+1]"
                    echo "    6→[3×3]  7→[3+3+1]  8→[4×4]"
                    echo ""
                    echo "  All panes run: claude --dangerously-skip-permissions"
                    echo ""
                    ;;
                *)
                    _dev_ensure_iterm2 || return 1
                    local launch_fn="_dev_split_launch"
                    [[ "$split_cwd" == true ]] && launch_fn="_dev_split_launch_cwd"
                    if _dev_split_tab_exists; then
                        local choice=""
                        read -r "choice?devterm split tab exists. [f]ocus or [k]ill and start fresh? "
                        case "$choice" in
                            k|K)
                                _dev_split_close_tab
                                "$launch_fn"
                                ;;
                            *)
                                _dev_split_focus_tab
                                ;;
                        esac
                    else
                        "$launch_fn"
                    fi
                    ;;
            esac
            ;;
        *)
            _dev_ensure_iterm2 || return 1
            if _dev_tab_exists; then
                local choice
                read -r "choice?devterm tab exists. [f]ocus or [k]ill and start fresh? "
                case "$choice" in
                    k|K)
                        _dev_close_tab
                        _dev_launch
                        ;;
                    *)
                        _dev_focus_tab
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
        'kill:close the devterm tab'
        'stop:close the devterm tab'
        'status:show tab state'
        'info:show tab state'
        'config:show or change the code directory'
        'help:show usage reference'
        '-s:split mode — multiple Claude panes in a grid'
    )
    _describe 'devterm command' subcmds
}
# ── devterm -s: Single-project multi-Claude split mode ──

# _dev_split_state_file: Path to the file storing the split session ID
_dev_split_state_file() {
    echo "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/devterm-split.session_id"
}

# _dev_split_tab_exists: Check if the tracked split tab is still open
_dev_split_tab_exists() { _iterm2_tab_exists "$(_dev_split_state_file)"; }

# _dev_split_focus_tab: Bring the split tab to front
_dev_split_focus_tab() { _iterm2_focus_tab "$(_dev_split_state_file)"; }

# _dev_split_close_tab: Close the split iTerm2 tab
_dev_split_close_tab() { _iterm2_close_tab "$(_dev_split_state_file)" "devterm split"; }

# _dev_split_grid: Compute grid layout for n panes
# Output: space-separated row sizes (e.g. "3 3 1" for n=7)
_dev_split_grid() {
    local n="$1"
    if (( n <= 3 )); then
        echo "$n"
    elif (( n % 2 == 0 )); then
        echo "$(( n / 2 )) $(( n / 2 ))"
    else
        echo "$(( (n - 1) / 2 )) $(( (n - 1) / 2 )) 1"
    fi
}

# _dev_split_pick_project: Single-select project picker
_dev_split_pick_project() {
    local code_dir="$1"
    local names=()
    local branches=()

    for d in "$code_dir"/*/; do
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
    echo -e "  \033[1mdevterm split\033[0m — pick a project" >&2
    echo "" >&2
    for (( i=1; i<=${#names[@]}; i++ )); do
        printf "  \033[0;33m%2d\033[0m  %s \033[0;90m(%s)\033[0m\n" "$i" "${names[$i]}" "${branches[$i]}" >&2
    done
    echo "" >&2

    local input=""
    read -r "input?  Enter number: "
    if [[ -z "$input" || ! "$input" =~ ^[0-9]+$ ]] || (( input < 1 || input > ${#names[@]} )); then
        echo -e "\033[0;31m✗\033[0m Invalid selection" >&2
        return 1
    fi

    echo "${names[$input]}"
}

# _dev_split_equalize: Equalize all pane sizes via iTerm2 Python API
_dev_split_equalize() {
    local anchor_sid="$1"
    local grid_spec="$2"
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

    root = tab.root

    # Single pane — nothing to equalize
    if isinstance(root, iterm2.Session):
        return

    rows = [int(x) for x in "${grid_spec}".split()]

    if root.vertical:
        # Single row of columns — equalize widths
        total_w = sum(
            c.grid_size.width if isinstance(c, iterm2.Session) else
            sum(s.grid_size.width for s in c.sessions)
            for c in root.children
        )
        col_w = total_w // len(root.children)
        for child in root.children:
            if isinstance(child, iterm2.Session):
                child.preferred_size = iterm2.util.Size(col_w, child.grid_size.height)
    else:
        # Multiple rows — root is horizontal splitter
        all_sessions = list(root.sessions)
        total_h = sum(s.grid_size.height for s in all_sessions)
        num_rows = len(root.children)
        row_h = total_h // num_rows

        for i, child in enumerate(root.children):
            if isinstance(child, iterm2.Session):
                # Single-pane row (remainder)
                child.preferred_size = iterm2.util.Size(
                    child.grid_size.width, row_h)
            elif isinstance(child, iterm2.Splitter) and child.vertical:
                # Multi-column row — equalize column widths
                row_sessions = list(child.sessions)
                total_w = sum(s.grid_size.width for s in row_sessions)
                col_w = total_w // len(child.children)
                for col_child in child.children:
                    if isinstance(col_child, iterm2.Session):
                        col_child.preferred_size = iterm2.util.Size(
                            col_w, row_h)

    await tab.async_update_layout()

iterm2.run_until_complete(main)
PYEOF
}

# _dev_split_build: Build the iTerm2 grid layout for split mode
#
# Three-phase approach:
#   Phase 1 — Create tab, build row/column splits, cd all panes
#   Phase 2 — Equalize pane sizes via Python API
#   Phase 3 — Clear scrollback, set titles, launch Claude
_dev_split_build() {
    local project="$1"
    local pane_count="$2"
    local proj_dir="${3:-${DEVTMUX_DIR:-$HOME/code}/$project}"

    _dev_ensure_iterm2 || return 1

    # Clean up any tracked split tab
    if [[ -f "$(_dev_split_state_file)" ]]; then
        _dev_split_close_tab >/dev/null 2>&1
    fi

    # Get current window ID
    local current_window=""
    current_window=$("$_SHELLY_IT2API" show-focus 2>/dev/null | awk '/^Key window:/{print $3}')

    # Create new tab
    local output="" session_id=""
    output=$("$_SHELLY_IT2API" create-tab --window "$current_window" 2>/dev/null) || {
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Failed to create iTerm2 tab"
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
    echo "$session_id" > "$(_dev_split_state_file)"

    # Compute grid layout
    local grid_spec=""
    grid_spec="$(_dev_split_grid "$pane_count")"
    local rows=( ${(s: :)grid_spec} )
    local num_rows=${#rows[@]}

    # For a single pane, skip all splitting
    if (( pane_count == 1 )); then
        local all_sessions=("$session_id")
    else
        # ── Phase 1: Create splits ──

        # Step 1: Create rows via horizontal splits
        local row_anchors=("$session_id")
        local last_row="$session_id"
        local row_out="" row_sid=""
        for (( r=2; r<=num_rows; r++ )); do
            row_out=$("$_SHELLY_IT2API" split-pane "$last_row" 2>/dev/null)
            row_sid=${${(M)${=row_out}:#id=*}#id=}
            if [[ -z "$row_sid" ]]; then
                echo -e "\033[0;33m·\033[0m Warning: failed to create row $r" >&2
                break
            fi
            row_anchors+=("$row_sid")
            last_row="$row_sid"
        done

        # Step 2: Create columns within each row via vertical splits
        local all_sessions=()
        for (( r=1; r<=num_rows; r++ )); do
            local cols=${rows[$r]}
            local anchor="${row_anchors[$r]}"
            local last_col="$anchor"
            all_sessions+=("$anchor")

            for (( c=2; c<=cols; c++ )); do
                local col_out="" col_sid=""
                col_out=$("$_SHELLY_IT2API" split-pane "$last_col" --vertical 2>/dev/null)
                col_sid=${${(M)${=col_out}:#id=*}#id=}
                if [[ -z "$col_sid" ]]; then
                    echo -e "\033[0;33m·\033[0m Warning: failed to create column $c in row $r" >&2
                    break
                fi
                all_sessions+=("$col_sid")
                last_col="$col_sid"
            done
        done
    fi

    # Navigate all panes to project dir
    for sid in "${all_sessions[@]}"; do
        "$_SHELLY_IT2API" send-text "$sid" "cd ${(q)proj_dir} && clear"$'\n' 2>/dev/null
    done

    # ── Phase 2: Equalize sizes ──
    if (( pane_count > 1 )); then
        sleep 0.5
        _dev_split_equalize "$session_id" "$grid_spec"
    fi

    # ── Phase 3: Clear scrollback, set titles, launch Claude ──
    local pane_num=0
    for sid in "${all_sessions[@]}"; do
        (( pane_num++ ))
        "$_SHELLY_IT2API" inject "$sid" $'\033]1337;ClearScrollback\007' 2>/dev/null
        "$_SHELLY_IT2API" inject "$sid" "$(printf '\033]0;\xe2\x9a\xa1 %d :: %s\007' "$pane_num" "$project")" 2>/dev/null
        "$_SHELLY_IT2API" set-profile-property "$sid" allow_title_setting false 2>/dev/null
        "$_SHELLY_IT2API" send-text "$sid" "claude --dangerously-skip-permissions"$'\n' 2>/dev/null
    done

    # Focus first pane
    "$_SHELLY_IT2API" activate session "${all_sessions[1]}" 2>/dev/null
    "$_SHELLY_IT2API" activate-app 2>/dev/null

    # Print summary
    local layout_desc=""
    layout_desc=$(printf '%s' "${(j:×:)rows}")
    # shellcheck disable=SC2028
    echo "\033[0;32m✓\033[0m devterm split: $project ($layout_desc, $pane_count panes)"
}

# _dev_split_launch: Orchestrate project picker, pane count, and session build
_dev_split_launch() {
    local code_dir=""
    code_dir="$(_dev_get_code_dir)" || return 1

    local project=""
    project="$(_dev_split_pick_project "$code_dir")" || return 1

    local pane_count=""
    read -r "pane_count?  How many panes? (1-8): "
    if [[ -z "$pane_count" || ! "$pane_count" =~ ^[0-9]+$ ]] || (( pane_count < 1 || pane_count > 8 )); then
        echo -e "\033[0;31m✗\033[0m Invalid pane count (must be 1-8)" >&2
        return 1
    fi

    _dev_split_build "$project" "$pane_count"
}

# _dev_split_launch_cwd: Split mode in the current directory (skip project picker)
_dev_split_launch_cwd() {
    local proj_dir=""
    proj_dir="$(pwd)"
    local project="${proj_dir:t}"

    local pane_count=""
    echo "" >&2
    echo -e "  \033[1mdevterm split\033[0m — \033[0;36m$project\033[0m (current directory)" >&2
    echo "" >&2
    read -r "pane_count?  How many panes? (1-8): "
    if [[ -z "$pane_count" || ! "$pane_count" =~ ^[0-9]+$ ]] || (( pane_count < 1 || pane_count > 8 )); then
        echo -e "\033[0;31m✗\033[0m Invalid pane count (must be 1-8)" >&2
        return 1
    fi

    _dev_split_build "$project" "$pane_count" "$proj_dir"
}

# compdef registration moved to .zshrc (after compinit)
