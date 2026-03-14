# ── System Monitor Dashboard ──
# Author: Shreyas Ugemuge
#
# One command — `sysmon` — that installs all prerequisites and launches
# an iTerm2 monitoring window with:
#   • btop   → all CPU cores + memory + network (left pane)
#   • nvtop  → GPU % chart + VRAM bar          (right pane, top)
#   • macmon → CPU/GPU temp + power + freq      (right pane, bottom)
#
# Layout:
#  ┌──────────────┬──────────┐
#  │              │  nvtop   │
#  │  btop        │  GPU %   │
#  │  CPU+mem+net │  VRAM    │
#  │              ├──────────┤
#  │              │  macmon  │
#  │              │  Temp    │
#  │              │  Power   │
#  └──────────────┴──────────┘
#
# Usage:
#   sysmon          — launch dashboard (install deps if needed)
#   sysmon kill     — close the iTerm2 window
#   sysmon status   — check which monitor tools are installed
#   sysmon help     — quick reference

_IT2API="/Applications/iTerm.app/Contents/Resources/it2api"

# ── Detect package manager ──
_sysmon_pkg_install() {
    local pkg="$1"
    if command -v brew &>/dev/null; then
        brew install "$pkg"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    else
        # shellcheck disable=SC2028
        # zsh's echo expands \033 escape sequences by default; this is a zsh config file
        echo "\033[0;31m✗\033[0m No supported package manager found (brew/apt/dnf/pacman)"
        return 1
    fi
}

# ── Check if a GPU is present ──
_sysmon_has_gpu() {
    if $IS_MACOS; then
        system_profiler SPDisplaysDataType 2>/dev/null | grep -qi 'vendor\|chipset\|chip:' 2>/dev/null
    else
        lspci 2>/dev/null | grep -qiE 'VGA|3D|Display' 2>/dev/null
    fi
}

# ── Check if NVIDIA GPU ──
_sysmon_has_nvidia() {
    command -v nvidia-smi &>/dev/null || lspci 2>/dev/null | grep -qi nvidia 2>/dev/null
}

# ── State file path (stores session ID of the btop pane) ──
_sysmon_state_file() {
    echo "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/sysmon.session_id"
}

# ── Ensure running inside iTerm2 and Python module is available ──
_sysmon_ensure_iterm2() {
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m non-iTerm mode: sysmon requires iTerm2 (current terminal: ${TERM_PROGRAM:-unknown})"
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

# ── Check if sysmon window is still open ──
_sysmon_window_exists() {
    local sid
    sid="$(cat "$(_sysmon_state_file)" 2>/dev/null)" || return 1
    [[ -n "$sid" ]] && "$_IT2API" show-hierarchy 2>/dev/null | grep -q "id=$sid"
}

# ── Focus the sysmon window ──
_sysmon_focus_window() {
    local sid
    sid="$(cat "$(_sysmon_state_file)" 2>/dev/null)" || return 1
    "$_IT2API" activate session "$sid" 2>/dev/null
    "$_IT2API" activate-app 2>/dev/null
}

# ── Close the sysmon window ──
_sysmon_close_window() {
    local sid
    sid="$(cat "$(_sysmon_state_file)" 2>/dev/null)" || {
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m No sysmon window tracked"
        return 0
    }
    # Find window ID containing this session
    local hierarchy cur_win="" win_id=""
    hierarchy=$("$_IT2API" show-hierarchy 2>/dev/null)
    while IFS= read -r line; do
        if [[ "$line" =~ 'Window id=([^ ]+)' ]]; then
            cur_win="${match[1]}"
        elif [[ "$line" == *"id=$sid"* ]]; then
            win_id="$cur_win"
            break
        fi
    done <<< "$hierarchy"

    rm -f "$(_sysmon_state_file)"
    if [[ -n "$win_id" ]]; then
        local win_num="${win_id#w}"
        osascript -e "tell application \"iTerm2\" to close window id $win_num" 2>/dev/null
        # shellcheck disable=SC2028
        echo "\033[0;32m✓\033[0m sysmon window closed"
    else
        # shellcheck disable=SC2028
        echo "\033[0;90m·\033[0m sysmon window already closed"
    fi
}

# ── Install prerequisites ──
_sysmon_ensure_deps() {
    local missing=()
    local installed_something=false

    # Core: btop (iTerm2 handles the window management)
    command -v btop &>/dev/null || missing+=(btop)

    # nvtop — only if a GPU is present
    if _sysmon_has_gpu && ! command -v nvtop &>/dev/null; then
        if $IS_MACOS; then
            missing+=(nvtop)
        elif _sysmon_has_nvidia || lspci 2>/dev/null | grep -qiE 'AMD|ATI|Intel' 2>/dev/null; then
            missing+=(nvtop)
        fi
    fi

    # macmon — Apple Silicon thermal/power monitor (no sudo needed)
    if $IS_MACOS && ! command -v macmon &>/dev/null; then
        missing+=(vladkens/tap/macmon)
    fi

    if (( ${#missing[@]} == 0 )); then
        return 0
    fi

    echo ""
    echo -e "\033[0;36m·\033[0m sysmon: installing missing tools: \033[1m${missing[*]}\033[0m"
    echo ""

    for pkg in "${missing[@]}"; do
        echo -e "  \033[0;90m→\033[0m $pkg …"
        if _sysmon_pkg_install "$pkg" &>/dev/null; then
            echo -e "  \033[0;32m✓\033[0m $pkg installed"
            installed_something=true
        else
            echo -e "  \033[0;31m✗\033[0m $pkg failed — install manually"
        fi
    done

    if $installed_something; then
        echo ""
        echo -e "\033[0;32m✓\033[0m All dependencies ready"
    fi
}

# ── Build and launch the dashboard ──
_sysmon_launch() {
    # Preflight
    _sysmon_ensure_iterm2 || return 1
    if ! command -v btop &>/dev/null; then
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m btop is required but not installed"
        return 1
    fi

    # ── Force-write btop config: CPU + memory + network ──
    # Removes disks and process table so CPU core graphs get more space.
    # Written fresh on every launch.
    local btop_conf="${XDG_CONFIG_HOME:-$HOME/.config}/btop/btop.conf"
    mkdir -p "${btop_conf:h}"
    cat > "$btop_conf" << 'BTOPEOF'
#* sysmon-managed btop config — written fresh on every sysmon launch
shown_boxes = "cpu mem net"
graph_symbol = "braille"
graph_symbol_cpu = "braille"
graph_symbol_net = "braille"
theme_background = False
color_theme = "Default"
cpu_graph_upper = "total"
cpu_graph_lower = "user"
cpu_single_graph = False
show_coretemp = True
update_ms = 1000
rounded_corners = True
show_battery = True
net_auto = True
net_sync = True
BTOPEOF

    # ── Force-write nvtop config: hide all N/A fields on Apple Silicon ──
    # Keeps GPU % chart and VRAM bar, hides broken clock/temp/fan/power fields.
    # Written fresh on every launch.
    if $IS_MACOS; then
        local nvtop_conf="${XDG_CONFIG_HOME:-$HOME/.config}/nvtop/interface.ini"
        mkdir -p "${nvtop_conf:h}"
        cat > "$nvtop_conf" << 'NVTOPEOF'
[General]
UseColor = true
UpdateInterval = 1000

[Device 0]
DeviceId = 0
GPURate = true
GPUClockRate = false
VRAMRate = true
VRAMClockRate = false
Temperature = false
FanSpeed = false
Power = false
EncoderRate = false
DecoderRate = false
PCIE_TX = false
PCIE_RX = false

[Chart 0]
Displayed = true
Type = GPU_USAGE
DeviceId = 0

[Chart 1]
Displayed = true
Type = VRAM_USAGE
DeviceId = 0

[Processes]
DisplayField0 = PID
DisplayField1 = GPU_USAGE
DisplayField2 = VRAM_USAGE
DisplayField3 = COMMAND
SortBy = GPU_USAGE
SortOrder = Descending
NVTOPEOF
    else
        # On Linux, clean slate — let nvtop use defaults (fields work there)
        rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvtop/interface.ini" 2>/dev/null
    fi

    local has_gpu=false
    local has_nvtop=false
    local has_macmon=false
    _sysmon_has_gpu && has_gpu=true
    command -v nvtop &>/dev/null && has_nvtop=true
    command -v macmon &>/dev/null && has_macmon=true

    # ── Create iTerm2 window with btop ──
    local output session_id
    output=$("$_IT2API" create-tab --command btop 2>/dev/null) || {
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Failed to create iTerm2 window"
        echo "  Ensure Python API is enabled: iTerm2 → Preferences → General → Magic → Enable Python API"
        return 1
    }
    # Parse session ID: output format is "Session "name" id=SESSION_ID WxH frame=..."
    session_id=${${(M)${=output}:#id=*}#id=}
    if [[ -z "$session_id" ]]; then
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Could not parse session ID from it2api output"
        return 1
    fi

    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    echo "$session_id" > "$(_sysmon_state_file)"

    if $has_gpu && $has_nvtop; then
        # Split right for nvtop (vertical divider = new pane to the right)
        local nvtop_out nvtop_sid
        nvtop_out=$("$_IT2API" split-pane "$session_id" --vertical 2>/dev/null)
        nvtop_sid=${${(M)${=nvtop_out}:#id=*}#id=}
        "$_IT2API" send-text "$nvtop_sid" $'nvtop\n' 2>/dev/null

        if $has_macmon; then
            # Split nvtop pane horizontally for macmon (new pane below)
            local macmon_out macmon_sid
            macmon_out=$("$_IT2API" split-pane "$nvtop_sid" 2>/dev/null)
            macmon_sid=${${(M)${=macmon_out}:#id=*}#id=}
            "$_IT2API" send-text "$macmon_sid" $'macmon\n' 2>/dev/null
        fi
    elif $has_macmon; then
        # No GPU/nvtop — macmon on the right
        local macmon_out macmon_sid
        macmon_out=$("$_IT2API" split-pane "$session_id" --vertical 2>/dev/null)
        macmon_sid=${${(M)${=macmon_out}:#id=*}#id=}
        "$_IT2API" send-text "$macmon_sid" $'macmon\n' 2>/dev/null
    fi

    # Focus btop pane
    "$_IT2API" activate session "$session_id" 2>/dev/null
    "$_IT2API" activate-app 2>/dev/null
}

# ── Status check ──
_sysmon_status() {
    local _d='\033[0;90m'
    local _g='\033[0;32m'
    local _r='\033[0;31m'
    local _n='\033[0m'

    echo ""
    echo -e "${_d}── sysmon status ──${_n}"

    for tool in btop nvtop macmon; do
        if command -v "$tool" &>/dev/null; then
            local ver
            case "$tool" in
                btop)   ver="$(btop --version 2>/dev/null | head -1 | awk '{print $NF}')" ;;
                nvtop)  ver="$(nvtop --version 2>/dev/null | head -1 | awk '{print $NF}')" ;;
                macmon) ver="$(macmon --version 2>/dev/null | awk '{print $NF}')" ;;
            esac
            echo -e "  ${_g}✓${_n} ${tool}  ${_d}${ver}${_n}"
        else
            if [[ "$tool" == "macmon" ]] && ! $IS_MACOS; then
                echo -e "  ${_d}·${_n} ${tool}  ${_d}macOS only${_n}"
            else
                echo -e "  ${_r}✗${_n} ${tool}  ${_d}not installed${_n}"
            fi
        fi
    done

    # iTerm2
    if [[ -d "/Applications/iTerm.app" ]]; then
        local iterm_ver
        iterm_ver=$(defaults read /Applications/iTerm.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo "?")
        echo -e "  ${_g}✓${_n} iTerm2  ${_d}${iterm_ver}${_n}"
    else
        echo -e "  ${_r}✗${_n} iTerm2  ${_d}not installed${_n}"
    fi

    echo ""
    if _sysmon_has_gpu; then
        echo -e "  ${_d}GPU${_n}  detected"
    else
        echo -e "  ${_d}GPU${_n}  none detected (nvtop pane will be skipped)"
    fi

    echo ""
    if _sysmon_window_exists; then
        echo -e "  ${_d}Window${_n}  ${_g}open${_n} — \`sysmon\` to focus, \`sysmon kill\` to close"
    else
        echo -e "  ${_d}Window${_n}  not open — \`sysmon\` to start"
    fi
    echo ""
}

# ── Main entry point ──
function sysmon() {
    case "${1:-}" in
        kill|stop)
            _sysmon_close_window
            ;;
        status|info)
            _sysmon_status
            ;;
        help|-h|--help)
            echo ""
            echo "  sysmon           launch the monitoring dashboard"
            echo "  sysmon kill      close the iTerm2 window"
            echo "  sysmon status    check installed tools & window"
            echo "  sysmon help      show this message"
            echo ""
            echo "  Dashboard panes:"
            echo "    btop       all CPU cores + memory + network (braille)"
            echo "    nvtop      GPU utilization + VRAM (if GPU present)"
            echo "    macmon     CPU/GPU temp + power + frequency (macOS)"
            echo ""
            echo "  Requires iTerm2 with Python API enabled:"
            echo "    Preferences → General → Magic → Enable Python API"
            echo ""
            ;;
        *)
            _sysmon_ensure_deps
            if _sysmon_window_exists; then
                # shellcheck disable=SC2028
                echo "\033[0;90m·\033[0m Focusing existing sysmon window…"
                _sysmon_focus_window
            else
                _sysmon_launch
            fi
            ;;
    esac
}

# ── Tab completion for sysmon ──
_sysmon_completion() {
    # shellcheck disable=SC2034
    # subcmds is consumed by _describe, which shellcheck cannot trace
    local -a subcmds=(
        'kill:close the iTerm2 window'
        'stop:close the iTerm2 window'
        'status:check installed tools and window state'
        'info:check installed tools and window state'
        'help:show usage and pane reference'
    )
    _describe 'sysmon command' subcmds
}
# compdef registration moved to .zshrc (after compinit)
