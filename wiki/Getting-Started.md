# Getting Started

## Prerequisites

### Hard dependencies (you install these)

| Tool | macOS | Ubuntu/WSL | Fedora | Arch |
|------|-------|------------|--------|------|
| zsh  | included | `sudo apt install zsh` | `sudo dnf install zsh` | `sudo pacman -S zsh` |
| git  | `xcode-select --install` | `sudo apt install git` | `sudo dnf install git` | `sudo pacman -S git` |
| curl | included | `sudo apt install curl` | included | included |
| Homebrew | [brew.sh](https://brew.sh) — auto-installed by `deps.zsh` if missing | n/a | n/a | n/a |

### Auto-installed on first shell open

`config/deps.zsh` runs once a day and installs anything missing via your platform's package manager:

| Kind | Packages | Notes |
|------|----------|-------|
| zsh plugins | `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions` | all platforms |
| CLI tools | `eza`, `figlet`, `tree` | all platforms |
| Casks (macOS) | `font-meslo-lg-nerd-font` | Nerd Font used for `eza` icons in `ll`; iTerm2's Default profile is auto-wired to use it as the Non-ASCII Font (your main text font is untouched) |

On Linux, cask installs are skipped. Install a Nerd Font manually (e.g. `sudo apt install fonts-firacode`) and configure your terminal to use it if you want icon glyphs in `ll`.

### macOS-only features

`sysmon`, `devterm`, `pan`, and `mactop` require **iTerm2** with the **Python API enabled**:

1. Open iTerm2 Preferences (Cmd+,)
2. General → Magic → Enable Python API
3. Shelly will install the `iterm2` Python module on first use

In any other terminal (Terminal.app, Ghostty, etc.) these features print a "non-iTerm mode" message and exit cleanly.

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
