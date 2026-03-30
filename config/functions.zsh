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
        # Layer 1: macOS notification via iTerm2 OSC 9
        printf '\033]9;%s\007' "$msg"
        # Layer 2: Dock bounce once (catches attention when iTerm2 is not focused)
        printf '\033]1337;RequestAttention=once\007'
    fi
}

# ── cc: Claude Code with completion notification ──
function cc() {
    claude "$@"
    ccnotify "Claude done — $(basename "$PWD")"
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

# ── shelly: Project management CLI ──

function shelly() {
    case "$1" in
        release) shift; _shelly_release "$@" ;;
        version) cat "$(git rev-parse --show-toplevel 2>/dev/null)/VERSION" 2>/dev/null || echo "not in shelly repo" ;;
        help|*)
            echo "" >&2
            echo -e "  \033[1mshelly\033[0m — project management for shelly" >&2
            echo "" >&2
            echo "  shelly release <major|minor|patch>  Bump version, update changelog, commit, tag, push" >&2
            echo "  shelly version                      Show current version" >&2
            echo "  shelly help                         Show this help" >&2
            echo "" >&2
            ;;
    esac
}

function _shelly_release() {
    local bump_type="$1"
    local repo_root=""
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"

    if [[ -z "$repo_root" || ! -f "$repo_root/VERSION" ]]; then
        echo "shelly release: must be run from the shelly repo" >&2
        return 1
    fi

    if [[ "$bump_type" != "major" && "$bump_type" != "minor" && "$bump_type" != "patch" ]]; then
        echo "Usage: shelly release <major|minor|patch>" >&2
        return 1
    fi

    # Check for clean working tree
    if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
        echo -e "\033[0;31m✗\033[0m  Working tree is dirty — commit or stash changes first" >&2
        return 1
    fi

    # Read current version
    local current=""
    current="$(<"$repo_root/VERSION")"
    current="${current%%$'\n'}"

    # Parse semver
    local major="" minor="" patch=""
    major="${current%%.*}"
    local rest="${current#*.}"
    minor="${rest%%.*}"
    patch="${rest#*.}"

    # Bump
    case "$bump_type" in
        major) major=$(( major + 1 )); minor=0; patch=0 ;;
        minor) minor=$(( minor + 1 )); patch=0 ;;
        patch) patch=$(( patch + 1 )) ;;
    esac

    local new_version="$major.$minor.$patch"
    local today=""
    today="$(date +%Y-%m-%d)"

    # Check for unreleased changes in CHANGELOG
    local changelog="$repo_root/CHANGELOG.md"
    local unreleased_content=""
    unreleased_content="$(awk '/^## \[Unreleased\]/{found=1; next} /^## \[/{if(found) exit} found{print}' "$changelog")"

    if [[ -z "${unreleased_content//[$'\n\r\t ']/}" ]]; then
        echo -e "\033[0;33m⚠\033[0m  No changes under [Unreleased] in CHANGELOG.md" >&2
        echo "  Add changelog entries before releasing." >&2
        return 1
    fi

    # Derive repo URL from git remote (strip .git suffix, normalize SSH to HTTPS)
    local repo_url=""
    repo_url="$(git -C "$repo_root" remote get-url origin 2>/dev/null)"
    repo_url="${repo_url%.git}"
    repo_url="${repo_url/git@github.com:/https:\/\/github.com\/}"

    # Confirm
    echo "" >&2
    echo -e "  \033[1mshelly release\033[0m" >&2
    echo -e "  v$current → \033[0;32mv$new_version\033[0m ($today)" >&2
    echo "" >&2
    echo "  This will:" >&2
    echo "    1. Update VERSION to $new_version" >&2
    echo "    2. Move [Unreleased] → [$new_version] in CHANGELOG.md" >&2
    echo "    3. Commit: chore: release v$new_version" >&2
    echo "    4. Tag: v$new_version" >&2
    echo "    5. Push commit and tag to origin" >&2
    echo "" >&2

    local confirm=""
    read -r "confirm?  Proceed? (y/N): "
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted." >&2
        return 1
    fi

    echo "" >&2

    # 1. Update VERSION
    echo "$new_version" > "$repo_root/VERSION"
    echo -e "  \033[0;32m✓\033[0m VERSION → $new_version" >&2

    # 2. Update CHANGELOG.md — insert new version header below [Unreleased]
    awk -v ver="$new_version" -v date="$today" '
    /^## \[Unreleased\]/ {
        print
        print ""
        print "## [" ver "] - " date
        next
    }
    {print}
    ' "$changelog" > "$changelog.tmp" && mv "$changelog.tmp" "$changelog"

    # Update [Unreleased] compare link to point to new version tag
    sed -i '' "s|\[Unreleased\]:.*compare/v.*\.\.\.HEAD|[Unreleased]: $repo_url/compare/v${new_version}...HEAD|" "$changelog"

    # Add new version compare link after [Unreleased] link line
    local escaped_url="${repo_url//\//\\/}"
    sed -i '' "/^\[Unreleased\]:.*HEAD$/a\\
[$new_version]: $escaped_url/compare/v${current}...v${new_version}" "$changelog"

    echo -e "  \033[0;32m✓\033[0m CHANGELOG.md updated" >&2

    # 3. Commit
    git -C "$repo_root" add VERSION CHANGELOG.md
    git -C "$repo_root" commit -q -m "chore: release v$new_version"
    echo -e "  \033[0;32m✓\033[0m Committed: chore: release v$new_version" >&2

    # 4. Tag
    git -C "$repo_root" tag "v$new_version"
    echo -e "  \033[0;32m✓\033[0m Tagged: v$new_version" >&2

    # 5. Push
    git -C "$repo_root" push -q origin master 2>&1
    git -C "$repo_root" push -q origin "v$new_version" 2>&1
    echo -e "  \033[0;32m✓\033[0m Pushed to origin" >&2

    echo "" >&2
    echo -e "  \033[0;32m✓ v$new_version released\033[0m" >&2
    echo "" >&2
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

    # Check common directory names
    local common_dirs=("code" "projects" "dev" "src" "repos" "workspace" "work")
    for name in "${common_dirs[@]}"; do
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

# _dev_tab_exists: Check if the tracked devterm tab is still open
_dev_tab_exists() {
    local sid
    sid="$(cat "$(_dev_state_file)" 2>/dev/null)" || return 1
    [[ -n "$sid" ]] && "$_IT2API_DEV" show-hierarchy 2>/dev/null | grep -q "id=$sid"
}

# _dev_focus_tab: Bring the devterm tab to front
_dev_focus_tab() {
    local sid
    sid="$(cat "$(_dev_state_file)" 2>/dev/null)" || return 1
    "$_IT2API_DEV" activate session "$sid" 2>/dev/null
    "$_IT2API_DEV" activate-app 2>/dev/null
}

# _dev_close_tab: Close the devterm iTerm2 tab
_dev_close_tab() {
    local sid
    sid="$(cat "$(_dev_state_file)" 2>/dev/null)" || {
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m No devterm tab tracked"
        return 0
    }
    local hierarchy cur_win="" cur_tab="" win_id="" tab_id=""
    hierarchy=$("$_IT2API_DEV" show-hierarchy 2>/dev/null)
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

    rm -f "$(_dev_state_file)"
    if [[ -n "$win_id" && -n "$tab_id" ]]; then
        local win_num="${win_id#w}"
        local tab_num="${tab_id#t}"
        osascript -e "tell application \"iTerm2\" to close (first tab of window id $win_num whose id = $tab_num)" 2>/dev/null
        # shellcheck disable=SC2028
        echo "\033[0;32m✓\033[0m devterm tab closed"
    else
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m devterm tab already closed"
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

    # Clean up any tracked tab before creating a new one
    if [[ -f "$(_dev_state_file)" ]]; then
        _dev_close_tab >/dev/null 2>&1
    fi

    # Get current window ID so we create a tab, not a new window
    local current_window
    current_window=$("$_IT2API_DEV" show-focus 2>/dev/null | awk '/^Key window:/{print $3}')

    # Create new tab in the current iTerm2 window
    local output session_id
    output=$("$_IT2API_DEV" create-tab --window "$current_window" 2>/dev/null) || {
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
_dev_split_tab_exists() {
    local sid=""
    sid="$(cat "$(_dev_split_state_file)" 2>/dev/null)" || return 1
    [[ -n "$sid" ]] && "$_IT2API_DEV" show-hierarchy 2>/dev/null | grep -q "id=$sid"
}

# _dev_split_focus_tab: Bring the split tab to front
_dev_split_focus_tab() {
    local sid=""
    sid="$(cat "$(_dev_split_state_file)" 2>/dev/null)" || return 1
    "$_IT2API_DEV" activate session "$sid" 2>/dev/null
    "$_IT2API_DEV" activate-app 2>/dev/null
}

# _dev_split_close_tab: Close the split iTerm2 tab
_dev_split_close_tab() {
    local sid=""
    sid="$(cat "$(_dev_split_state_file)" 2>/dev/null)" || {
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m No devterm split tab tracked"
        return 0
    }
    local hierarchy="" cur_win="" cur_tab="" win_id="" tab_id=""
    hierarchy=$("$_IT2API_DEV" show-hierarchy 2>/dev/null)
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

    rm -f "$(_dev_split_state_file)"
    if [[ -n "$win_id" && -n "$tab_id" ]]; then
        local win_num="${win_id#w}"
        local tab_num="${tab_id#t}"
        osascript -e "tell application \"iTerm2\" to close (first tab of window id $win_num whose id = $tab_num)" 2>/dev/null
        # shellcheck disable=SC2028
        echo "\033[0;32m✓\033[0m devterm split tab closed"
    else
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m devterm split tab already closed"
    fi
}

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
    current_window=$("$_IT2API_DEV" show-focus 2>/dev/null | awk '/^Key window:/{print $3}')

    # Create new tab
    local output="" session_id=""
    output=$("$_IT2API_DEV" create-tab --window "$current_window" 2>/dev/null) || {
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
            row_out=$("$_IT2API_DEV" split-pane "$last_row" 2>/dev/null)
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
                col_out=$("$_IT2API_DEV" split-pane "$last_col" --vertical 2>/dev/null)
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
        "$_IT2API_DEV" send-text "$sid" "cd ${(q)proj_dir} && clear"$'\n' 2>/dev/null
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
        "$_IT2API_DEV" inject "$sid" $'\033]1337;ClearScrollback\007' 2>/dev/null
        "$_IT2API_DEV" inject "$sid" "$(printf '\033]0;\xe2\x9a\xa1 %d :: %s\007' "$pane_num" "$project")" 2>/dev/null
        "$_IT2API_DEV" set-profile-property "$sid" allow_title_setting false 2>/dev/null
        "$_IT2API_DEV" send-text "$sid" "claude --dangerously-skip-permissions"$'\n' 2>/dev/null
    done

    # Focus first pane
    "$_IT2API_DEV" activate session "${all_sessions[1]}" 2>/dev/null
    "$_IT2API_DEV" activate-app 2>/dev/null

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
