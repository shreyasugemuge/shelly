# ── Startup Info ──
# Author: Shreyas Ugemuge
#
# Displays system specs and network info on every interactive shell open.
# Kept fast: local commands only for system info, async-safe for network.

# Only run in interactive shells
[[ ! -o interactive ]] && return 0

_D='\033[0;90m'   # dim gray (labels)
_N='\033[0m'      # reset (values stay default)

# ── System ──
_sys_os=""
_sys_cpu=""
_sys_gpu=""
_sys_ram=""
_sys_host=""

if [[ "$OSTYPE" == darwin* ]]; then
    _sys_os="macOS $(sw_vers -productVersion 2>/dev/null) ($(uname -m))"
    _sys_cpu="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
    _sys_gpu="$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model|Chip:/{print $2; exit}')"
    _sys_ram="$(( $(sysctl -n hw.memsize 2>/dev/null) / 1073741824 )) GB"
    _sys_host="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
elif [[ "$OSTYPE" == linux* ]]; then
    if [[ -f /etc/os-release ]]; then
        _sys_os="$(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m))"
    else
        _sys_os="Linux $(uname -r) ($(uname -m))"
    fi
    _sys_cpu="$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null)"
    _sys_gpu="$(lspci 2>/dev/null | awk -F': ' '/VGA|3D/{print $2; exit}')"
    _sys_ram="$(awk '/MemTotal/{printf "%.0f GB", $2/1048576}' /proc/meminfo 2>/dev/null)"
    _sys_host="$(hostname -s 2>/dev/null)"
fi

echo ""
echo -e "${_D}── System ──${_N}"
echo -e "  ${_sys_host}"
echo -e "  ${_D}OS${_N}   ${_sys_os}"
echo -e "  ${_D}CPU${_N}  ${_sys_cpu}"
[[ -n "$_sys_gpu" ]] && echo -e "  ${_D}GPU${_N}  ${_sys_gpu}"
echo -e "  ${_D}RAM${_N}  ${_sys_ram}"

unset _sys_os _sys_cpu _sys_gpu _sys_ram _sys_host

# ── Network ──
_net_pub="$(curl -s --max-time 2 ipinfo.io/ip 2>/dev/null || echo 'unavailable')"
if [[ "$OSTYPE" == darwin* ]]; then
    _net_iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
    _net_loc="$(ipconfig getifaddr "${_net_iface:-en0}" 2>/dev/null || echo 'not connected')"
    _net_ssid="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk '/ SSID:/{print $2}')"
    _net_dns="$(scutil --dns 2>/dev/null | awk '/nameserver\[0\]/{print $3; exit}')"
else
    _net_loc="$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'not connected')"
    _net_ssid="$(iwgetid -r 2>/dev/null)"
    _net_dns="$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null)"
fi

echo ""
echo -e "${_D}── Network ──${_N}"
echo -e "  ${_D}Public${_N}  ${_net_pub}"
echo -e "  ${_D}Local${_N}   ${_net_loc}"
[[ -n "$_net_ssid" ]] && echo -e "  ${_D}Wi-Fi${_N}   ${_net_ssid}"
[[ -n "$_net_dns" ]]  && echo -e "  ${_D}DNS${_N}     ${_net_dns}"
echo ""

unset _net_pub _net_loc _net_iface _net_ssid _net_dns
unset _D _N
