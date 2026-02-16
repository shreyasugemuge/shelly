# ── Plugins ──
# Author: Shreyas Ugemuge
#
# Lightweight plugin loading — no framework needed.
# Currently: zsh-autosuggestions, zsh-syntax-highlighting

# ── zsh-autosuggestions ──
# Shows ghost-text suggestions from history as you type.
# Press → (right arrow) to accept, or keep typing to ignore.
if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=245'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# ── zsh-syntax-highlighting ──
# Colors commands as you type: green = valid, red = not found.
# MUST be sourced last (after all other plugins and widgets).
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
