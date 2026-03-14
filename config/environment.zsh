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

# ── NVM (Node Version Manager) — lazy loaded ──
# Stub functions defer sourcing NVM until first use (~300ms savings)
export NVM_DIR="$HOME/.nvm"

_nvm_script=""
if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    _nvm_script="/opt/homebrew/opt/nvm/nvm.sh"
elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    _nvm_script="/usr/local/opt/nvm/nvm.sh"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    _nvm_script="$HOME/.nvm/nvm.sh"
fi

if [[ -n "$_nvm_script" ]]; then
    # Add NVM-managed node to PATH without sourcing the full script
    [[ -d "$NVM_DIR/versions/node" ]] && {
        local _default_node
        _default_node="$(ls -d "$NVM_DIR/versions/node/"* 2>/dev/null | sort -V | tail -1)"
        [[ -n "$_default_node" ]] && export PATH="$_default_node/bin:$PATH"
    }

    _lazy_load_nvm() {
        unfunction nvm node npm npx 2>/dev/null
        source "$_nvm_script"
        unset _nvm_script
    }
    for _cmd in nvm node npm npx; do
        eval "${_cmd}() { _lazy_load_nvm; ${_cmd} \"\$@\" }"
    done
    unset _cmd
else
    unset _nvm_script
fi

# ── PATH Deduplication ──
# Remove duplicate entries; preserves first-occurrence order.
typeset -U path
export PATH
