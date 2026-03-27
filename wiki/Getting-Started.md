# Getting Started

## Prerequisites

| Tool | macOS | Ubuntu/WSL | Fedora | Arch |
|------|-------|------------|--------|------|
| zsh  | included | `sudo apt install zsh` | `sudo dnf install zsh` | `sudo pacman -S zsh` |
| git  | `xcode-select --install` | `sudo apt install git` | `sudo dnf install git` | `sudo pacman -S git` |
| curl | included | `sudo apt install curl` | included | included |

Everything else (zsh plugins, CLI tools) is installed automatically on first shell open.

## Install

```bash
git clone https://github.com/shreyasugemuge/shelly.git ~/.dotfiles/zsh
cd ~/.dotfiles/zsh
./install.sh
exec zsh
```

The install script copies `.zshrc` and `config/` into `~/.config/zsh/` and backs up any existing configs. You can clone to any path — `~/.dotfiles/zsh` is just a convention.

## Preview Without Changes

```bash
./install.sh --dry-run
```

## Uninstall

```bash
./install.sh --uninstall
```

This restores your backed-up configs.

## Update

Pull the latest changes and re-run the installer:

```bash
cd ~/.dotfiles/zsh   # or wherever you cloned
git pull
./install.sh
exec zsh
```

## Local Overrides

Put machine-specific config in `~/.zshrc.local` — it's sourced at the end of `.zshrc` and never tracked by git.

```bash
# ~/.zshrc.local example
export DEVTMUX_DIR="$HOME/projects"
alias myalias="some-command"
```
