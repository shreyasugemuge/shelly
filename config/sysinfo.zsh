# ── fetch: Startup Splash ──
# Author: Shreyas Ugemuge
#
# A personalized system splash screen on every interactive shell open.
# ASCII art + system stats side-by-side. Fast — no network calls.
#
# Aesthetic: muted labels, meaningful values, personality.

# Only run in interactive shells
[[ ! -o interactive ]] && return 0

# ── Colors ──
_D='\033[0;90m'     # dim gray (labels, art)
_A='\033[0;33m'     # yellow (accent — matches prompt face)
_N='\033[0m'        # reset

# ── Gather system info (local only — fast) ──
_f_host=""
_f_os=""
_f_cpu=""
_f_gpu=""
_f_ram=""
_f_uptime=""
_f_shell=""
_f_brew=""
_f_packages=""

_f_shell="zsh ${ZSH_VERSION}"

if $IS_MACOS; then
    _f_host="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
    _f_os="macOS $(sw_vers -productVersion 2>/dev/null) ($(uname -m))"
    _f_cpu="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
    _f_gpu="$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model|Chip:/{print $2; exit}')"
    _f_ram="$(( $(sysctl -n hw.memsize 2>/dev/null) / 1073741824 )) GB"
    # macOS uptime: parse boot time
    _f_boot="$(sysctl -n kern.boottime 2>/dev/null | awk '{print $4}' | tr -d ',')"
    if [[ -n "$_f_boot" ]]; then
        _f_now="$(date +%s)"
        _f_secs=$(( _f_now - _f_boot ))
        _f_days=$(( _f_secs / 86400 ))
        _f_hours=$(( (_f_secs % 86400) / 3600 ))
        _f_mins=$(( (_f_secs % 3600) / 60 ))
        if (( _f_days > 0 )); then
            _f_uptime="${_f_days}d ${_f_hours}h ${_f_mins}m"
        elif (( _f_hours > 0 )); then
            _f_uptime="${_f_hours}h ${_f_mins}m"
        else
            _f_uptime="${_f_mins}m"
        fi
        unset _f_boot _f_now _f_secs _f_days _f_hours _f_mins
    fi
    # Package count
    if command -v brew &>/dev/null; then
        _f_brew="$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"
        _f_packages="${_f_brew} (brew)"
    fi
elif $IS_LINUX; then
    _f_host="$(hostname -s 2>/dev/null)"
    if [[ -f /etc/os-release ]]; then
        _f_os="$(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m))"
    else
        _f_os="Linux $(uname -r) ($(uname -m))"
    fi
    _f_cpu="$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null)"
    _f_gpu="$(lspci 2>/dev/null | awk -F': ' '/VGA|3D/{print $2; exit}')"
    _f_ram="$(awk '/MemTotal/{printf "%.0f GB", $2/1048576}' /proc/meminfo 2>/dev/null)"
    _f_uptime="$(uptime -p 2>/dev/null | sed 's/up //' || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    # Package count
    if command -v apt &>/dev/null; then
        _f_packages="$(dpkg --list 2>/dev/null | grep -c '^ii') (apt)"
    elif command -v brew &>/dev/null; then
        _f_packages="$(brew list --formula 2>/dev/null | wc -l | tr -d ' ') (brew)"
    elif command -v pacman &>/dev/null; then
        _f_packages="$(pacman -Q 2>/dev/null | wc -l | tr -d ' ') (pacman)"
    fi
fi

# ── Git streak (commits today in any repo) ──
_f_streak=""
if command -v git &>/dev/null; then
    _f_today_commits="$(git -C "$HOME" log --all --oneline --since='midnight' --author="$(git config user.name 2>/dev/null)" 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$_f_today_commits" -gt 0 ]] 2>/dev/null; then
        _f_streak="${_f_today_commits} today"
    fi
    unset _f_today_commits
fi

# ── Fortune / quote (if available, keep it short) ──
_f_quote=""
if command -v fortune &>/dev/null; then
    _f_quote="$(fortune -s 2>/dev/null | head -2)"
fi

# ── ASCII art — randomized from a small set ──
# Kept compact (8 lines tall) so it doesn't eat the terminal
_f_art_index=$(( RANDOM % 4 ))

case $_f_art_index in
    0)
_f_art=(
"    ${_A}    ╱╲${_N}"
"    ${_A}   ╱  ╲${_N}"
"    ${_A}  ╱    ╲${_N}"
"    ${_A} ╱──────╲${_N}"
"    ${_A}╱   ${_D}◉  ◉${_A}  ╲${_N}"
"    ${_A}╲   ${_D} ‿‿ ${_A}  ╱${_N}"
"    ${_A} ╲──────╱${_N}"
"    ${_A}  ╲    ╱${_N}"
) ;;
    1)
_f_art=(
"    ${_D}┌─────────┐${_N}"
"    ${_D}│${_A} ◖     ◗ ${_D}│${_N}"
"    ${_D}│${_A}    ▽    ${_D}│${_N}"
"    ${_D}│${_A}  ╰───╯  ${_D}│${_N}"
"    ${_D}├─────────┤${_N}"
"    ${_D}│ ${_N}>${_D}_${_N}<     ${_D}│${_N}"
"    ${_D}│         │${_N}"
"    ${_D}└─────────┘${_N}"
) ;;
    2)
_f_art=(
"    ${_D}    ┏━━━┓${_N}"
"    ${_D}  ┏━┛   ┗━┓${_N}"
"    ${_D}  ┃ ${_A}●   ● ${_D}┃${_N}"
"    ${_D}  ┃ ${_A}  ▼   ${_D}┃${_N}"
"    ${_D}  ┃ ${_A} ───  ${_D}┃${_N}"
"    ${_D}  ┗━┓   ┏━┛${_N}"
"    ${_D}    ┗━━━┛${_N}"
"    ${_D}   ╱     ╲${_N}"
) ;;
    3)
_f_art=(
"    ${_D}  ╭───────╮${_N}"
"    ${_D}  │ ${_A}◉${_D}   ${_A}◉${_D} │${_N}"
"    ${_D}  │ ${_A} ╶─╴ ${_D} │${_N}"
"    ${_D}  ╰───┬───╯${_N}"
"    ${_D}    ╭─┴─╮${_N}"
"    ${_D}   ╱│   │╲${_N}"
"    ${_D}    │   │${_N}"
"    ${_D}    ╰───╯${_N}"
) ;;
esac

# ── Build the stats column ──
_f_stats=()
_f_stats+=("${_A}${_f_host}${_N}")
_f_stats+=("${_D}os${_N}       ${_f_os}")
_f_stats+=("${_D}cpu${_N}      ${_f_cpu}")
[[ -n "$_f_gpu" ]] && _f_stats+=("${_D}gpu${_N}      ${_f_gpu}")
_f_stats+=("${_D}ram${_N}      ${_f_ram}")
_f_stats+=("${_D}uptime${_N}   ${_f_uptime}")
_f_stats+=("${_D}shell${_N}    ${_f_shell}")
[[ -n "$_f_packages" ]] && _f_stats+=("${_D}packages${_N} ${_f_packages}")
[[ -n "$_f_streak" ]] && _f_stats+=("${_D}commits${_N}  ${_f_streak}")

# ── Render side-by-side ──
echo ""
_f_lines=$(( ${#_f_art[@]} > ${#_f_stats[@]} ? ${#_f_art[@]} : ${#_f_stats[@]} ))
for (( i=1; i<=_f_lines; i++ )); do
    _f_left="${_f_art[$i]:-}"
    _f_right="${_f_stats[$i]:-}"
    # Pad art column to ~20 visible chars (art is ~18 + escape codes)
    printf "%b  %b\n" "${_f_left}" "${_f_right}"
done

# ── Quote (below the card) ──
if [[ -n "$_f_quote" ]]; then
    echo ""
    echo -e "    ${_D}${_f_quote}${_N}"
fi

echo ""

# ── Cleanup ──
unset _D _A _N
unset _f_host _f_os _f_cpu _f_gpu _f_ram _f_uptime _f_shell _f_brew _f_packages
unset _f_streak _f_quote _f_art _f_art_index _f_stats _f_lines _f_left _f_right
