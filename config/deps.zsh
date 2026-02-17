# ── Dependency Check ──
# Author: Shreyas Ugemuge
#
# On first run (or once per day): ensures Homebrew and required
# packages are installed. Stays completely silent when everything
# is already in place.

# ── Required Homebrew formulae ──
# Only what .zshrc actually needs — nothing extra.
_zsh_deps=(
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# ── Run at most once per day ──
_deps_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/deps_checked"
[[ -d "${_deps_stamp:h}" ]] || mkdir -p "${_deps_stamp:h}"

_should_check_deps() {
    if [[ -f "$_deps_stamp" ]]; then
        local stamp_day today
        if [[ "$OSTYPE" == darwin* ]]; then
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

if _should_check_deps; then
    # ── Step 1: Homebrew ──
    if ! command -v brew &>/dev/null; then
        echo ""
        echo -e "\033[0;33m⚠  Homebrew not found — installing…\033[0m"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for the rest of this session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        if command -v brew &>/dev/null; then
            echo -e "\033[0;32m✓\033[0m Homebrew installed"
        else
            echo -e "\033[0;31m✗\033[0m Homebrew installation failed — install manually from https://brew.sh"
            touch "$_deps_stamp"
            unset _deps_stamp _zsh_deps
            unfunction _should_check_deps 2>/dev/null
            return 0
        fi
    fi

    # ── Step 2: Missing packages ──
    _missing=()
    for _pkg in "${_zsh_deps[@]}"; do
        if [[ ! -d "$(brew --prefix)/share/$_pkg" ]]; then
            _missing+=("$_pkg")
        fi
    done

    if (( ${#_missing[@]} )); then
        echo -e "\033[0;36m·\033[0m Installing missing dependencies: \033[1m${_missing[*]}\033[0m"
        brew install "${_missing[@]}" 2>&1 | tail -1
        echo -e "\033[0;32m✓\033[0m Done. Restart your shell:  \033[1mexec zsh\033[0m"
    fi
    unset _missing _pkg

    touch "$_deps_stamp"
fi

unset _deps_stamp _zsh_deps
unfunction _should_check_deps 2>/dev/null
