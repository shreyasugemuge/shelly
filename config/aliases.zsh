# ── Aliases ──
# Author: Shreyas Ugemuge

# ── File Operations ──
alias rm='rm -i'
alias ..='cd ..'
alias ...='cd ../..'
# macOS (BSD) uses -G for color, Linux (GNU) uses --color=auto
if ls --color=auto /dev/null &>/dev/null; then
    alias ls='ls -h --color=auto'
else
    alias ls='ls -hG'
fi
alias la='ls -a'
alias lla='ls -la'

# ll: long listing powered by eza when available, ls -lh otherwise.
# eza auto-scales sizes (B/K/M/G) and color-grades the size column so large
# files visually pop. Falls back cleanly when stdout is a pipe.
if command -v eza &>/dev/null; then
    function ll() {
        local -a display_flags flags paths
        if [[ -t 1 ]]; then
            display_flags=(--color=always --icons=auto)
        else
            display_flags=(--color=never --icons=never)
        fi
        # Split args into flags and paths so we can default the path to '.'
        # when the user passes only flags (eza emits nothing without a target).
        local arg
        for arg in "$@"; do
            if [[ "$arg" == -* ]]; then flags+=("$arg"); else paths+=("$arg"); fi
        done
        (( ${#paths} == 0 )) && paths=(.)
        eza --long --header --git --group-directories-first \
            --time-style=long-iso --color-scale=size \
            "${display_flags[@]}" "${flags[@]}" "${paths[@]}"
    }
else
    alias ll='ls -lh'
fi

# ── Config Management ──
alias zshrc='${EDITOR:-vim} ~/.zshrc'
alias zshconfig='${EDITOR:-vim} ~/.config/zsh/'
alias refresh='exec zsh'

# ── Network ──
alias globip='echo "public: $(curl -s --max-time 3 ipinfo.io/ip)"'
# shellcheck disable=SC2142
# locip uses nested command substitution with awk; the \$2 escaping is intentional for awk field access
alias locip='echo "local: $(ipconfig getifaddr "$(route -n get default 2>/dev/null | awk "/interface:/{print \$2}")" 2>/dev/null || hostname -I 2>/dev/null | awk "{print \$1}")"'
alias myip='globip && locip'
alias wifistat='ifconfig en0 2>/dev/null || ip addr show wlan0 2>/dev/null'

# ── Git ──
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gitget='git fetch && git pull'
alias gitsend='git add -A && git commit && git push'
alias gitlog='git log -10 --pretty=oneline'

# ── Top / Monitoring ──
alias mytop='top -o mem -O cpu 2>/dev/null || top'

# ── Tree ──
alias tre='tree -C -L 2'

# ── Fun ──
alias yell='figlet'

# ── Claude Code (prevent display sleep while running) ──
alias claude='caffeinate -disu claude'

# ── ComfyUI Monitor (requires ComfyUI's venv for websockets) ──
: "${SHELLY_COMFY_DIR:=$HOME/Comfy}"
if [[ -x "$SHELLY_COMFY_DIR/.venv/bin/python" ]]; then
    alias comfy-monitor="$SHELLY_COMFY_DIR/.venv/bin/python ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/scripts/comfy_monitor.py"
fi

# ── Typo Corrections ──
alias celar='clear'
alias vlear='clear'
alias cls='clear'
