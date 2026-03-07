#!/bin/bash
# ── Shelly Installer ──
# Author: Shreyas Ugemuge
#
# Symlinks shelly's zsh config files into the right places
# on your system.
#
# Usage:
#   ./install.sh            Normal install
#   ./install.sh --dry-run  Show what would happen without doing it
#   ./install.sh --uninstall Remove symlinks and restore backups

set -euo pipefail

# ── Config ──
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "unknown")
ZSHRC_TARGET="$HOME/.zshrc"
ZSH_CONFIG_DIR="$HOME/.config/zsh"
BACKUP_DIR="$HOME/.zsh_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
UNINSTALL=false

# ── Colors ──
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}→${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${CYAN}·${NC} $1"; }

# ── Parse args ──
for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=true ;;
        --uninstall) UNINSTALL=true ;;
        --version|-v)
            echo "shelly v${VERSION}"
            exit 0
            ;;
        --help|-h)
            echo "shelly v${VERSION}"
            echo ""
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run      Show what would happen without making changes"
            echo "  --uninstall    Remove symlinks and show backup location"
            echo "  --version, -v  Print version and exit"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
    esac
done

# ── Preflight checks ──
check_zsh() {
    if ! command -v zsh &>/dev/null; then
        err "zsh is not installed"
        echo ""
        echo "  Install it with:"
        echo "    macOS:  brew install zsh"
        echo "    Ubuntu: sudo apt install zsh"
        exit 1
    fi
    ok "zsh found: $(zsh --version | head -1)"
}

# ── Backup existing configs ──
backup_existing() {
    local backed_up=false

    if [[ -f "$ZSHRC_TARGET" && ! -L "$ZSHRC_TARGET" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$ZSHRC_TARGET" "$BACKUP_DIR/.zshrc"
        backed_up=true
    fi

    if [[ -d "$ZSH_CONFIG_DIR" && ! -L "$ZSH_CONFIG_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$ZSH_CONFIG_DIR" "$BACKUP_DIR/zsh"
        backed_up=true
    fi

    if $backed_up; then
        warn "Existing configs backed up to $BACKUP_DIR"
    fi
}

# ── Create symlinks ──
create_symlinks() {
    if [[ -L "$ZSHRC_TARGET" ]]; then
        rm "$ZSHRC_TARGET"
    elif [[ -f "$ZSHRC_TARGET" ]]; then
        rm "$ZSHRC_TARGET"
    fi

    if [[ -L "$ZSH_CONFIG_DIR" ]]; then
        rm "$ZSH_CONFIG_DIR"
    elif [[ -d "$ZSH_CONFIG_DIR" ]]; then
        rm -rf "$ZSH_CONFIG_DIR"
    fi

    mkdir -p "$(dirname "$ZSH_CONFIG_DIR")"

    ln -s "$REPO_DIR/.zshrc" "$ZSHRC_TARGET"
    ln -s "$REPO_DIR/config" "$ZSH_CONFIG_DIR"

    ok "~/.zshrc → $REPO_DIR/.zshrc"
    ok "~/.config/zsh → $REPO_DIR/config"
}

# ── Ensure zsh data/cache dirs exist ──
create_dirs() {
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    ok "Created data and cache directories"
}

# ── Set default shell ──
maybe_set_default_shell() {
    local zsh_path
    zsh_path="$(which zsh)"

    if [[ "$SHELL" == "$zsh_path" ]]; then
        ok "zsh is already your default shell"
        return
    fi

    echo ""
    read -rp "  Set zsh as your default shell? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        chsh -s "$zsh_path"
        ok "Default shell changed to zsh"
        warn "Open a new terminal for this to take effect"
    else
        info "Skipped — you can run 'chsh -s $(which zsh)' later"
    fi
}

# ── Uninstall ──
do_uninstall() {
    echo ""
    echo -e "${YELLOW}Uninstalling shelly...${NC}"
    echo ""

    if [[ -L "$ZSHRC_TARGET" ]]; then
        rm "$ZSHRC_TARGET"
        ok "Removed ~/.zshrc symlink"
    fi

    if [[ -L "$ZSH_CONFIG_DIR" ]]; then
        rm "$ZSH_CONFIG_DIR"
        ok "Removed ~/.config/zsh symlink"
    fi

    local latest_backup
    latest_backup=$(ls -dt "$HOME"/.zsh_backup_* 2>/dev/null | head -1)
    if [[ -n "$latest_backup" ]]; then
        warn "Your most recent backup is at: $latest_backup"
        info "Restore with: cp $latest_backup/.zshrc ~/.zshrc"
    fi

    echo ""
    ok "Uninstall complete"
    exit 0
}

# ── Dry run ──
do_dry_run() {
    echo ""
    echo -e "${CYAN}Dry run — no changes will be made${NC}"
    echo ""
    check_zsh
    info "Would back up existing configs (if any)"
    info "Would symlink ~/.zshrc → $REPO_DIR/.zshrc"
    info "Would symlink ~/.config/zsh → $REPO_DIR/config"
    info "Would create ~/.local/share/zsh and ~/.cache/zsh"
    info "Would auto-install missing Homebrew dependencies on first shell open"
    info "Would offer to set zsh as default shell"
    echo ""
    ok "Dry run complete — run without --dry-run to install"
    exit 0
}

# ── Main ──
main() {
    echo ""
    echo -e "${CYAN}── Shelly Installer v${VERSION} ──${NC}"
    echo ""

    if $UNINSTALL; then
        do_uninstall
    fi

    if $DRY_RUN; then
        do_dry_run
    fi

    check_zsh
    backup_existing
    create_symlinks
    create_dirs
    maybe_set_default_shell

    echo ""
    ok "Installation complete!"
    echo ""
    info "Reload your shell:  exec zsh"
    info "Edit config:        zshrc"
    info "Edit modules:       zshconfig"
    echo ""
}

main "$@"
