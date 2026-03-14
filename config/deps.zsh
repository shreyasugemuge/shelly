# ── Dependency Check ──
# Author: Shreyas Ugemuge
#
# On first run (or once per day): ensures required zsh plugins
# are installed. Uses the native package manager for each platform.
# Stays completely silent when everything is already in place.

# ── Required plugins ──
_zsh_deps=(
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

# ── Required CLI tools (used by aliases/functions) ──
_cli_deps=(
    figlet
    tree
)

# ── Run at most once per day ──
_deps_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/deps_checked"
[[ -d "${_deps_stamp:h}" ]] || mkdir -p "${_deps_stamp:h}"

_should_check_deps() {
    if [[ -f "$_deps_stamp" ]]; then
        local stamp_day today
        if $IS_MACOS; then
            stamp_day="$(stat -f '%Sm' -t '%Y-%m-%d' "$_deps_stamp" 2>/dev/null)"
        else
            stamp_day="$(date -r "$_deps_stamp" '+%Y-%m-%d' 2>/dev/null)"
        fi
        today="$(date '+%Y-%m-%d')"
        [[ "$stamp_day" != "$today" ]]
    else
        return 0
    fi
}

# ── Check if a dependency is already installed ──
_plugin_installed() {
    local plugin="$1"
    local brew_share
    brew_share="${_SHELLY_BREW_PREFIX}/share"
    for _dir in "$brew_share" /usr/share /usr/local/share; do
        [[ -f "$_dir/$plugin/$plugin.zsh" ]] && return 0
    done
    return 1
}

# ── Install missing packages via the platform's package manager ──
_install_missing() {
    local -a missing=()
    for _pkg in "${_zsh_deps[@]}"; do
        _plugin_installed "$_pkg" || missing+=("$_pkg")
    done
    for _pkg in "${_cli_deps[@]}"; do
        command -v "$_pkg" &>/dev/null || missing+=("$_pkg")
    done

    (( ${#missing[@]} )) || return 0

    echo -e "\033[0;36m·\033[0m Installing missing packages: \033[1m${missing[*]}\033[0m"

    if $IS_MACOS; then
        # macOS: use Homebrew (install it first if missing)
        if ! command -v brew &>/dev/null; then
            echo -e "\033[0;33m⚠  Homebrew not found — installing…\033[0m"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            if ! command -v brew &>/dev/null; then
                echo -e "\033[0;31m✗\033[0m Homebrew installation failed — install manually from https://brew.sh"
                return 1
            fi
            echo -e "\033[0;32m✓\033[0m Homebrew installed"
        fi
        brew install "${missing[@]}" 2>&1 | tail -1
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "${missing[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${missing[@]}"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "${missing[@]}"
    elif command -v brew &>/dev/null; then
        # Linux with Homebrew (linuxbrew)
        brew install "${missing[@]}" 2>&1 | tail -1
    else
        echo -e "\033[0;31m✗\033[0m No supported package manager found (brew/apt/dnf/pacman)"
        echo "  Install manually: ${missing[*]}"
        return 1
    fi

    echo -e "\033[0;32m✓\033[0m Done. Restart your shell:  \033[1mexec zsh\033[0m"
}

if _should_check_deps; then
    _install_missing && touch "$_deps_stamp"
fi

unset _deps_stamp _zsh_deps _cli_deps
unfunction _should_check_deps _plugin_installed _install_missing 2>/dev/null
