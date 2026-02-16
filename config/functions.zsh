# ── Functions ──
# Author: Shreyas Ugemuge

# ── pan: Open man page as PDF in Preview (macOS) ──
function pan() {
    if [[ -z "$1" ]]; then
        echo "Usage: pan <command>"
        return 1
    fi
    if [[ "$OSTYPE" == darwin* ]]; then
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
    if [[ "$OSTYPE" == darwin* ]]; then
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
    lsof -i :"$1"
}
