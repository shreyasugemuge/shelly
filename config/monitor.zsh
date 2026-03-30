# ── System Monitor Dashboard ──
# Author: Shreyas Ugemuge
#
# One command — `sysmon` — that installs all prerequisites and launches
# an iTerm2 monitoring tab with:
#   • btop   → all CPU cores + memory + network (left pane)
#   • mactop → GPU util/freq + ANE + power + thermals (right pane)
#
# Layout:
#  ┌──────────────┬──────────────┐
#  │              │              │
#  │  btop        │  mactop      │
#  │  CPU cores   │  GPU util    │
#  │  Memory      │  GPU freq    │
#  │  Network     │  ANE         │
#  │              │  Power draw  │
#  │              │  Thermals    │
#  │              │  E/P cores   │
#  └──────────────┴──────────────┘
#
# Usage:
#   sysmon          — launch dashboard (install deps if needed)
#   sysmon kill     — close the sysmon tab
#   sysmon status   — check which monitor tools are installed
#   sysmon help     — quick reference
#
# Legacy:
#   sysmon-old      — launch old nvtop+macmon layout
#   sysmon-old kill  — close the old layout tab

# iTerm2 API path provided by iterm2.zsh as $_SHELLY_IT2API

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
_sysmon_ensure_iterm2() { _iterm2_ensure "sysmon"; }

# ── Check if sysmon tab is still open ──
_sysmon_tab_exists() { _iterm2_tab_exists "$(_sysmon_state_file)"; }

# ── Focus the sysmon tab ──
_sysmon_focus_tab() { _iterm2_focus_tab "$(_sysmon_state_file)"; }

# ── Close the sysmon tab ──
_sysmon_close_tab() {
    _iterm2_close_tab "$(_sysmon_state_file)" "sysmon" \
        "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/sysmon.dim_state"
}

# ── Force-write btop config (shared by sysmon and sysmon-old) ──
# Removes disks and process table so CPU core graphs get more space.
_sysmon_write_btop_conf() {
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
}

# ── Save current dim state and disable dimming ──
_sysmon_disable_dimming() {
    local dim_state_file="$1"
    local cur_dim=""
    cur_dim=$(defaults read com.googlecode.iterm2 DimInactiveSplitPanes 2>/dev/null)
    echo "${cur_dim:-1}" > "$dim_state_file"
    defaults write com.googlecode.iterm2 DimInactiveSplitPanes -bool false
}

# ── Install prerequisites ──
_sysmon_ensure_deps() {
    local missing=()
    local installed_something=false

    # Core: btop (iTerm2 handles the window management)
    command -v btop &>/dev/null || missing+=(btop)

    # mactop — Apple Silicon GPU/ANE/power/thermal monitor (no sudo needed)
    if $IS_MACOS && ! command -v mactop &>/dev/null; then
        missing+=(mactop)
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

    _sysmon_write_btop_conf

    # ── Force-write mactop theme: per-component colors ──
    # Muted palette — each metric gets its own hue so you can scan at a glance.
    # Written fresh on every launch.
    local mactop_theme="$HOME/.mactop/theme.json"
    mkdir -p "${mactop_theme:h}"
    cat > "$mactop_theme" << 'MACTOPEOF'
{
  "background":          "#00000000",
  "foreground":          "#a0a0b0",
  "cpu":                 "#8be9fd",
  "gpu":                 "#bd93f9",
  "memory":              "#50fa7b",
  "ane":                 "#ffb86c",
  "power":               "#ff79c6",
  "network":             "#6272a4",
  "systemInfo":          "#6272a4",
  "processList":         "#a0a0b0",
  "processListDim":      "#555568"
}
MACTOPEOF

    local has_mactop=false
    command -v mactop &>/dev/null && has_mactop=true

    # ── Get current window ID so we create a tab, not a new window ──
    local current_window
    current_window=$("$_SHELLY_IT2API" show-focus 2>/dev/null | awk '/^Key window:/{print $3}')

    # ── Create new tab in the current iTerm2 window ──
    local output session_id
    output=$("$_SHELLY_IT2API" create-tab --window "$current_window" 2>/dev/null) || {
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Failed to create iTerm2 tab"
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

    # Launch btop via send-text (more reliable than --command for splitting)
    "$_SHELLY_IT2API" send-text "$session_id" $'btop\n' 2>/dev/null
    sleep 0.5

    if $has_mactop; then
        # Single vertical split: mactop on the right
        local mactop_out mactop_sid
        mactop_out=$("$_SHELLY_IT2API" split-pane "$session_id" --vertical 2>/dev/null)
        mactop_sid=${${(M)${=mactop_out}:#id=*}#id=}
        if [[ -n "$mactop_sid" ]]; then
            "$_SHELLY_IT2API" send-text "$mactop_sid" $'mactop\n' 2>/dev/null
        else
            # shellcheck disable=SC2028
            echo "\033[0;33m·\033[0m mactop pane failed to create"
        fi
    fi

    # Disable dimming so all sysmon panes are equally visible
    _sysmon_disable_dimming "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/sysmon.dim_state"

    # Focus btop pane
    "$_SHELLY_IT2API" activate session "$session_id" 2>/dev/null
    "$_SHELLY_IT2API" activate-app 2>/dev/null
}

# ── Status check ──
_sysmon_status() {
    local _d='\033[0;90m'
    local _g='\033[0;32m'
    local _r='\033[0;31m'
    local _n='\033[0m'

    echo ""
    echo -e "${_d}── sysmon status ──${_n}"

    for tool in btop mactop; do
        if command -v "$tool" &>/dev/null; then
            local ver=""
            case "$tool" in
                btop)   ver="$(btop --version 2>/dev/null | head -1 | awk '{print $NF}')" ;;
                mactop) ver="$(mactop --version 2>/dev/null | head -1 | awk '{print $NF}')" ;;
            esac
            echo -e "  ${_g}✓${_n} ${tool}  ${_d}${ver}${_n}"
        else
            if [[ "$tool" == "mactop" ]] && ! $IS_MACOS; then
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
        echo -e "  ${_d}GPU${_n}  none detected"
    fi

    echo ""
    if _sysmon_tab_exists; then
        echo -e "  ${_d}Tab${_n}  ${_g}open${_n} — \`sysmon\` to focus, \`sysmon kill\` to close"
    else
        echo -e "  ${_d}Tab${_n}  not open — \`sysmon\` to start"
    fi
    echo ""
}

# ── Main entry point ──
function sysmon() {
    case "${1:-}" in
        kill|stop)
            _sysmon_close_tab
            ;;
        status|info)
            _sysmon_status
            ;;
        help|-h|--help)
            echo ""
            echo "  sysmon           launch the monitoring dashboard"
            echo "  sysmon kill      close the sysmon tab"
            echo "  sysmon status    check installed tools & tab"
            echo "  sysmon help      show this message"
            echo ""
            echo "  Dashboard panes:"
            echo "    btop       all CPU cores + memory + network (braille)"
            echo "    mactop     GPU util/freq + ANE + power + thermals (macOS)"
            echo ""
            echo "  Legacy layout: sysmon-old (nvtop + macmon)"
            echo ""
            echo "  Requires iTerm2 with Python API enabled:"
            echo "    Preferences → General → Magic → Enable Python API"
            echo ""
            ;;
        *)
            _sysmon_ensure_iterm2 || return 1
            _sysmon_ensure_deps
            if _sysmon_tab_exists; then
                # shellcheck disable=SC2028
                echo "\033[0;90m·\033[0m Focusing existing sysmon tab…"
                _sysmon_focus_tab
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
        'kill:close the sysmon tab'
        'stop:close the sysmon tab'
        'status:check installed tools and tab state'
        'info:check installed tools and tab state'
        'help:show usage and pane reference'
    )
    _describe 'sysmon command' subcmds
}
# compdef registration moved to .zshrc (after compinit)

# ══════════════════════════════════════════════════════════════════════
# sysmon-old — Legacy layout (btop + nvtop + macmon)
# Kept as a fallback; uses its own state file so it won't clash with sysmon.
# ══════════════════════════════════════════════════════════════════════

_sysmon_old_state_file() {
    echo "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/sysmon-old.session_id"
}

_sysmon_old_tab_exists() { _iterm2_tab_exists "$(_sysmon_old_state_file)"; }

_sysmon_old_focus_tab() { _iterm2_focus_tab "$(_sysmon_old_state_file)"; }

_sysmon_old_close_tab() {
    _iterm2_close_tab "$(_sysmon_old_state_file)" "sysmon-old" \
        "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/sysmon-old.dim_state"
}

_sysmon_old_launch() {
    _sysmon_ensure_iterm2 || return 1
    if ! command -v btop &>/dev/null; then
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m btop is required but not installed"
        return 1
    fi

    _sysmon_write_btop_conf

    # Force-write nvtop config: hide N/A fields on Apple Silicon
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
    fi

    local has_gpu=false
    local has_nvtop=false
    local has_macmon=false
    _sysmon_has_gpu && has_gpu=true
    command -v nvtop &>/dev/null && has_nvtop=true
    command -v macmon &>/dev/null && has_macmon=true

    # Get current window ID so we create a tab, not a new window
    local current_window
    current_window=$("$_SHELLY_IT2API" show-focus 2>/dev/null | awk '/^Key window:/{print $3}')

    # Create new tab in the current iTerm2 window
    local output session_id
    output=$("$_SHELLY_IT2API" create-tab --window "$current_window" 2>/dev/null) || {
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Failed to create iTerm2 tab"
        return 1
    }
    session_id=${${(M)${=output}:#id=*}#id=}
    if [[ -z "$session_id" ]]; then
        # shellcheck disable=SC2028
        echo "\033[0;31m✗\033[0m Could not parse session ID from it2api output"
        return 1
    fi

    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    echo "$session_id" > "$(_sysmon_old_state_file)"

    "$_SHELLY_IT2API" send-text "$session_id" $'btop\n' 2>/dev/null
    sleep 0.5

    if $has_gpu && $has_nvtop; then
        local nvtop_out nvtop_sid
        nvtop_out=$("$_SHELLY_IT2API" split-pane "$session_id" --vertical 2>/dev/null)
        nvtop_sid=${${(M)${=nvtop_out}:#id=*}#id=}
        if [[ -z "$nvtop_sid" ]]; then
            # shellcheck disable=SC2028
            echo "\033[0;33m·\033[0m nvtop pane failed to create"
        else
            "$_SHELLY_IT2API" send-text "$nvtop_sid" $'nvtop\n' 2>/dev/null
            if $has_macmon; then
                sleep 0.3
                local macmon_out macmon_sid
                macmon_out=$("$_SHELLY_IT2API" split-pane "$nvtop_sid" 2>/dev/null)
                macmon_sid=${${(M)${=macmon_out}:#id=*}#id=}
                if [[ -n "$macmon_sid" ]]; then
                    "$_SHELLY_IT2API" send-text "$macmon_sid" $'macmon\n' 2>/dev/null
                else
                    # shellcheck disable=SC2028
                    echo "\033[0;33m·\033[0m macmon pane failed to create"
                fi
            fi
        fi
    elif $has_macmon; then
        local macmon_out macmon_sid
        macmon_out=$("$_SHELLY_IT2API" split-pane "$session_id" --vertical 2>/dev/null)
        macmon_sid=${${(M)${=macmon_out}:#id=*}#id=}
        if [[ -n "$macmon_sid" ]]; then
            "$_SHELLY_IT2API" send-text "$macmon_sid" $'macmon\n' 2>/dev/null
        else
            # shellcheck disable=SC2028
            echo "\033[0;33m·\033[0m macmon pane failed to create"
        fi
    fi

    # Disable dimming
    _sysmon_disable_dimming "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/sysmon-old.dim_state"

    "$_SHELLY_IT2API" activate session "$session_id" 2>/dev/null
    "$_SHELLY_IT2API" activate-app 2>/dev/null
}

function sysmon-old() {
    case "${1:-}" in
        kill|stop)
            _sysmon_old_close_tab
            ;;
        help|-h|--help)
            echo ""
            echo "  sysmon-old       launch the legacy dashboard (btop + nvtop + macmon)"
            echo "  sysmon-old kill  close the tab"
            echo ""
            ;;
        *)
            _sysmon_ensure_iterm2 || return 1
            if _sysmon_old_tab_exists; then
                # shellcheck disable=SC2028
                echo "\033[0;90m·\033[0m Focusing existing sysmon-old tab…"
                _sysmon_old_focus_tab
            else
                _sysmon_old_launch
            fi
            ;;
    esac
}
