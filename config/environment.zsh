# ── Environment Variables ──
# Author: Shreyas Ugemuge

# ── XDG Base Directories ──
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# ── Editor ──
export EDITOR="emacs"
export VISUAL="$EDITOR"

# ── Locale ──
export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── GPG ──
export GPG_TTY=$(tty)

# ── Zsh Options ──
setopt AUTO_CD              # cd by typing directory name
setopt EXTENDED_GLOB        # advanced globbing
setopt CORRECT              # suggest corrections for typos
setopt NO_BEEP              # no terminal beep
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell

# ── NVM (Node Version Manager) ──
# Only load if installed — checks Homebrew and default locations
if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    source "/opt/homebrew/opt/nvm/nvm.sh"
elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    source "/usr/local/opt/nvm/nvm.sh"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    source "$HOME/.nvm/nvm.sh"
fi
