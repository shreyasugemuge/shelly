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

# ── devtmux: Dynamic dev workspace ──

_DEVTMUX_SESSION="dev"

# _devtmux_persist_dir: Save DEVTMUX_DIR to ~/.zshrc.local (guards against duplicates)
_devtmux_persist_dir() {
    local dir="$1"
    local local_rc="$HOME/.zshrc.local"
    if [[ -f "$local_rc" ]] && grep -q 'DEVTMUX_DIR' "$local_rc"; then
        return 0
    fi
    echo "export DEVTMUX_DIR=\"${dir}\"" >> "$local_rc"
    echo -e "\033[0;90m·\033[0m Saved DEVTMUX_DIR to ~/.zshrc.local"
}

# _devtmux_get_code_dir: Discover code folder (env var, default, or prompt)
_devtmux_get_code_dir() {
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
        _devtmux_persist_dir "$dir"
        export DEVTMUX_DIR="$dir"
    fi
    echo "$dir"
}

# _devtmux_pick_projects: Interactive project picker (numbered list)
_devtmux_pick_projects() {
    local code_dir="$1"
    local names=()
    local branches=()

    for d in "$code_dir"/*/; do
        [[ -d "$d/.git" ]] || continue
        names+=("${d:t}")
        branches+=("$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')")
    done

    if (( ${#names[@]} == 0 )); then
        echo -e "\033[0;31m✗\033[0m No git repos found in $code_dir. Set DEVTMUX_DIR to a different folder." >&2
        return 1
    fi

    echo "" >&2
    echo -e "  \033[1mdevtmux\033[0m — pick 1-3 projects" >&2
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

# _devtmux_build_session: Build the tmux layout with one column per project
_devtmux_build_session() {
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

    # Create session with first project as working directory
    tmux new-session -d -s "$_DEVTMUX_SESSION" \
        -c "$code_dir/${projects[1]}" \
        -x "$(tput cols)" -y "$(tput lines)"

    # Add remaining columns (horizontal splits)
    for (( i=2; i<=count; i++ )); do
        tmux split-window -h -t "$_DEVTMUX_SESSION" \
            -c "$code_dir/${projects[$i]}"
    done

    # Equalize column widths — call ONCE, before any vertical splits
    tmux select-layout -t "$_DEVTMUX_SESSION" even-horizontal

    # Add 15% terminal pane at bottom of each column
    # After even-horizontal, columns are panes 0..(count-1)
    for (( i=1; i<=count; i++ )); do
        local top_idx=$(( (i-1) * 2 ))
        tmux split-window -v -t "$_DEVTMUX_SESSION:0.$top_idx" -p 15 \
            -c "$code_dir/${projects[$i]}"
    done

    # Launch Claude Code in each top pane (indices 0, 2, 4, ...)
    for (( i=1; i<=count; i++ )); do
        local top_pane=$(( (i-1) * 2 ))
        local claude_cmd="claude"
        if (( ${yolo_flags[$i]:-0} )); then
            claude_cmd="claude --dangerously-skip-permissions"
        fi
        tmux send-keys -t "$_DEVTMUX_SESSION:0.$top_pane" "clear && $claude_cmd" C-m
    done

    # Yell the project name in each bottom terminal pane (indices 1, 3, 5, ...)
    for (( i=1; i<=count; i++ )); do
        local bot_pane=$(( (i-1) * 2 + 1 ))
        tmux send-keys -t "$_DEVTMUX_SESSION:0.$bot_pane" "clear && figlet ${projects[$i]}" C-m
    done

    # Status bar — magenta/purple accent (distinct from sysmon amber)
    tmux set-option -t "$_DEVTMUX_SESSION" status on
    tmux set-option -t "$_DEVTMUX_SESSION" status-style 'bg=colour235,fg=colour248'
    # shellcheck disable=SC2296
    # ${(j:, :)projects} is zsh array join syntax (join with ", "); not valid in bash
    tmux set-option -t "$_DEVTMUX_SESSION" status-left " #[fg=colour135,bold]devtmux#[fg=colour248] | #[fg=colour183]${(j:, :)projects}#[fg=colour248] "
    tmux set-option -t "$_DEVTMUX_SESSION" status-left-length 60
    tmux set-option -t "$_DEVTMUX_SESSION" status-right '#[fg=colour245]Ctrl-b d detach '
    tmux set-option -t "$_DEVTMUX_SESSION" pane-border-style 'fg=colour237'
    tmux set-option -t "$_DEVTMUX_SESSION" pane-active-border-style 'fg=colour135'
    tmux set-option -t "$_DEVTMUX_SESSION" mouse on

    # Focus top-left pane
    tmux select-pane -t "$_DEVTMUX_SESSION:0.0"
}

# _devtmux_status: Show session state and tool availability
_devtmux_status() {
    echo ""
    if tmux has-session -t "$_DEVTMUX_SESSION" 2>/dev/null; then
        echo -e "  \033[0;32m✓\033[0m devtmux session running"
        echo ""
        tmux list-panes -t "$_DEVTMUX_SESSION" -F '    #{pane_index}: #{pane_current_path}'
    else
        echo -e "  \033[0;90m·\033[0m No devtmux session running"
    fi
    echo ""
}

# _devtmux_help: Show usage information
_devtmux_help() {
    echo ""
    echo "  devtmux           launch the dev workspace (interactive project picker)"
    echo "  devtmux kill      tear down the dev session"
    echo "  devtmux status    check session state and tool availability"
    echo "  devtmux help      show this message"
    echo ""
    echo "  Workspace layout:"
    echo "    1-3 projects    select from git repos in your code folder"
    echo "    add y suffix    skip permissions mode (e.g. 1y 3)"
    echo "    top pane        Claude Code (~85% height)"
    echo "    bottom pane     terminal (~15% height)"
    echo ""
    echo "  Inside the workspace:"
    echo "    mouse           click to switch panes, drag to resize"
    echo "    Ctrl-b d        detach (session keeps running)"
    echo ""
}

# _devtmux_launch: Orchestrate code folder discovery, picker, and session build
_devtmux_launch() {
    local code_dir
    code_dir="$(_devtmux_get_code_dir)" || return 1

    local projects_raw
    projects_raw="$(_devtmux_pick_projects "$code_dir")" || return 1

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

    _devtmux_build_session "${projects[@]}" -- "${yolo_flags[@]}"

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$_DEVTMUX_SESSION"
    else
        tmux attach-session -t "$_DEVTMUX_SESSION"
    fi
}

# devtmux: Entry point
function devtmux() {
    case "${1:-}" in
        kill|stop)
            if tmux has-session -t "$_DEVTMUX_SESSION" 2>/dev/null; then
                tmux kill-session -t "$_DEVTMUX_SESSION"
                echo -e "\033[0;32m✓\033[0m devtmux session terminated"
            else
                echo -e "\033[0;90m·\033[0m No devtmux session running"
            fi
            ;;
        status|info)
            _devtmux_status
            ;;
        help|-h|--help)
            _devtmux_help
            ;;
        *)
            if tmux has-session -t "$_DEVTMUX_SESSION" 2>/dev/null; then
                local choice
                read -r "choice?devtmux session exists. [r]eattach or [k]ill and start fresh? "
                case "$choice" in
                    k|K)
                        tmux kill-session -t "$_DEVTMUX_SESSION"
                        _devtmux_launch
                        ;;
                    *)
                        if [[ -n "$TMUX" ]]; then
                            tmux switch-client -t "$_DEVTMUX_SESSION"
                        else
                            tmux attach-session -t "$_DEVTMUX_SESSION"
                        fi
                        ;;
                esac
            else
                _devtmux_launch
            fi
            ;;
    esac
}

# ── Tab completion for devtmux ──
_devtmux_completion() {
    # shellcheck disable=SC2034
    # subcmds is consumed by _describe, which shellcheck cannot trace
    local -a subcmds=(
        'kill:tear down the devtmux session'
        'stop:tear down the devtmux session'
        'status:show session state and project panes'
        'info:show session state and project panes'
        'help:show usage reference'
    )
    _describe 'devtmux command' subcmds
}
# compdef registration moved to .zshrc (after compinit)
