# ── System Monitor Dashboard ──
# Author: Shreyas Ugemuge
#
# One command — `sysmon` — that installs all prerequisites and launches
# a tmux-based monitoring dashboard with:
#   • btop   → CPU, RAM, disk, processes  (main pane)
#   • nvtop  → GPU monitoring             (right pane, if GPU present)
#   • bandwhich → per-process network I/O  (bottom pane)
#
# Layout (with GPU):             Layout (without GPU):
#  ┌──────────┬─────────┐        ┌────────────────────┐
#  │          │         │        │                    │
#  │  btop    │  nvtop  │        │       btop         │
#  │          │         │        │                    │
#  ├──────────┴─────────┤        ├────────────────────┤
#  │    bandwhich        │        │     bandwhich       │
#  └────────────────────┘        └────────────────────┘
#
# Usage:
#   sysmon          — launch dashboard (install deps if needed)
#   sysmon kill     — tear down the dashboard session
#   sysmon status   — check which monitor tools are installed

_SYSMON_SESSION="sysmon"

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
        echo "\033[0;31m✗\033[0m No supported package manager found (brew/apt/dnf/pacman)"
        return 1
    fi
}

# ── Check if a GPU is present ──
_sysmon_has_gpu() {
    if [[ "$OSTYPE" == darwin* ]]; then
        # Apple Silicon has integrated GPU; discrete GPUs show in SPDisplaysDataType
        system_profiler SPDisplaysDataType 2>/dev/null | grep -qi 'vendor\|chipset\|chip:' 2>/dev/null
    else
        # Linux: check for NVIDIA/AMD/Intel discrete GPU
        lspci 2>/dev/null | grep -qiE 'VGA|3D|Display' 2>/dev/null
    fi
}

# ── Check if NVIDIA GPU (nvtop needs this or AMD ROCm) ──
_sysmon_has_nvidia() {
    command -v nvidia-smi &>/dev/null || lspci 2>/dev/null | grep -qi nvidia 2>/dev/null
}

# ── Install prerequisites ──
_sysmon_ensure_deps() {
    local missing=()
    local installed_something=false

    # tmux is required
    if ! command -v tmux &>/dev/null; then
        missing+=(tmux)
    fi

    # btop — the star of the show
    if ! command -v btop &>/dev/null; then
        missing+=(btop)
    fi

    # bandwhich — per-process network bandwidth
    if ! command -v bandwhich &>/dev/null; then
        missing+=(bandwhich)
    fi

    # nvtop — only if a GPU is present and nvtop isn't installed
    if _sysmon_has_gpu && ! command -v nvtop &>/dev/null; then
        if [[ "$OSTYPE" == darwin* ]]; then
            # nvtop on macOS supports Apple Silicon GPU via Metal
            missing+=(nvtop)
        elif _sysmon_has_nvidia || lspci 2>/dev/null | grep -qiE 'AMD|ATI|Intel' 2>/dev/null; then
            missing+=(nvtop)
        fi
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
    if ! command -v tmux &>/dev/null; then
        echo "\033[0;31m✗\033[0m tmux is required but not installed"
        return 1
    fi
    if ! command -v btop &>/dev/null; then
        echo "\033[0;31m✗\033[0m btop is required but not installed"
        return 1
    fi

    # Kill existing session if present
    tmux has-session -t "$_SYSMON_SESSION" 2>/dev/null && tmux kill-session -t "$_SYSMON_SESSION"

    local has_gpu=false
    local has_nvtop=false
    _sysmon_has_gpu && has_gpu=true
    command -v nvtop &>/dev/null && has_nvtop=true

    local has_bandwhich=false
    command -v bandwhich &>/dev/null && has_bandwhich=true

    # ── Build the layout ──
    # Start session with btop in the main pane
    tmux new-session -d -s "$_SYSMON_SESSION" -x "$(tput cols)" -y "$(tput lines)" 'btop'

    if $has_gpu && $has_nvtop; then
        # Split right for nvtop (40% width)
        tmux split-window -h -t "$_SYSMON_SESSION" -p 40 'nvtop'
        # Select the left pane (btop) then split bottom for network
        tmux select-pane -t "$_SYSMON_SESSION:0.0"
    fi

    if $has_bandwhich; then
        # Split bottom for bandwhich (25% height)
        # bandwhich needs sudo on Linux for packet capture
        if [[ "$OSTYPE" == darwin* ]]; then
            tmux split-window -v -t "$_SYSMON_SESSION:0.0" -p 25 'sudo bandwhich 2>/dev/null || bandwhich'
        else
            tmux split-window -v -t "$_SYSMON_SESSION:0.0" -p 25 'sudo bandwhich 2>/dev/null || bandwhich'
        fi
    fi

    # Focus back on btop (top-left)
    tmux select-pane -t "$_SYSMON_SESSION:0.0"

    # Set pane borders to look clean
    tmux set-option -t "$_SYSMON_SESSION" pane-border-style 'fg=colour237'
    tmux set-option -t "$_SYSMON_SESSION" pane-active-border-style 'fg=colour245'

    # Status bar — minimal, informative
    tmux set-option -t "$_SYSMON_SESSION" status on
    tmux set-option -t "$_SYSMON_SESSION" status-style 'bg=colour235,fg=colour248'
    tmux set-option -t "$_SYSMON_SESSION" status-left ' #[fg=colour214,bold]sysmon#[fg=colour248] │ '
    tmux set-option -t "$_SYSMON_SESSION" status-left-length 20
    tmux set-option -t "$_SYSMON_SESSION" status-right '#[fg=colour245]%H:%M │ q to exit pane '
    tmux set-option -t "$_SYSMON_SESSION" status-right-length 30

    # Allow mouse for easy pane switching/resizing
    tmux set-option -t "$_SYSMON_SESSION" mouse on

    # Attach
    tmux attach-session -t "$_SYSMON_SESSION"
}

# ── Status check ──
_sysmon_status() {
    local _d='\033[0;90m'
    local _g='\033[0;32m'
    local _r='\033[0;31m'
    local _n='\033[0m'

    echo ""
    echo -e "${_d}── sysmon status ──${_n}"

    for tool in tmux btop nvtop bandwhich; do
        if command -v "$tool" &>/dev/null; then
            local ver
            case "$tool" in
                tmux)      ver="$(tmux -V 2>/dev/null | awk '{print $2}')" ;;
                btop)      ver="$(btop --version 2>/dev/null | head -1 | awk '{print $NF}')" ;;
                nvtop)     ver="$(nvtop --version 2>/dev/null | head -1 | awk '{print $NF}')" ;;
                bandwhich) ver="$(bandwhich --version 2>/dev/null | awk '{print $2}')" ;;
            esac
            echo -e "  ${_g}✓${_n} ${tool}  ${_d}${ver}${_n}"
        else
            echo -e "  ${_r}✗${_n} ${tool}  ${_d}not installed${_n}"
        fi
    done

    echo ""
    if _sysmon_has_gpu; then
        echo -e "  ${_d}GPU${_n}  detected"
    else
        echo -e "  ${_d}GPU${_n}  none detected (nvtop pane will be skipped)"
    fi

    echo ""
    if tmux has-session -t "$_SYSMON_SESSION" 2>/dev/null; then
        echo -e "  ${_d}Session${_n}  ${_g}running${_n} — \`sysmon\` to reattach, \`sysmon kill\` to stop"
    else
        echo -e "  ${_d}Session${_n}  not running — \`sysmon\` to start"
    fi
    echo ""
}

# ── Main entry point ──
function sysmon() {
    case "${1:-}" in
        kill|stop)
            if tmux has-session -t "$_SYSMON_SESSION" 2>/dev/null; then
                tmux kill-session -t "$_SYSMON_SESSION"
                echo -e "\033[0;32m✓\033[0m sysmon session terminated"
            else
                echo -e "\033[0;90m·\033[0m No sysmon session running"
            fi
            ;;
        status|info)
            _sysmon_status
            ;;
        help|-h|--help)
            echo ""
            echo "  sysmon           launch the monitoring dashboard"
            echo "  sysmon kill      tear down the dashboard session"
            echo "  sysmon status    check installed tools & session"
            echo "  sysmon help      show this message"
            echo ""
            echo "  Dashboard panes:"
            echo "    btop       CPU, RAM, disk, processes"
            echo "    nvtop      GPU utilization (if GPU present)"
            echo "    bandwhich  per-process network bandwidth"
            echo ""
            echo "  Inside the dashboard:"
            echo "    mouse       click to switch panes, drag to resize"
            echo "    Ctrl-b d    detach (dashboard keeps running)"
            echo "    q           quit current pane's tool"
            echo ""
            ;;
        *)
            _sysmon_ensure_deps
            # Reattach if session exists and is detached
            if tmux has-session -t "$_SYSMON_SESSION" 2>/dev/null; then
                echo -e "\033[0;90m·\033[0m Reattaching to existing sysmon session…"
                tmux attach-session -t "$_SYSMON_SESSION"
            else
                _sysmon_launch
            fi
            ;;
    esac
}
