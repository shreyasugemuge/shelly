# Shelly

[![Version](https://img.shields.io/badge/version-4.8.0-blue.svg)](CHANGELOG.md)
[![Shell](https://img.shields.io/badge/shell-zsh-green.svg)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20WSL-orange.svg)](#prerequisites)

A modular zsh configuration and development workspace with an expressive prompt, smart completions, system monitoring dashboard, and auto-dependency management. macOS-first, Linux-compatible.

Named after a childhood nickname — and because it's a shell config.

## Highlights

- **Expressive prompt** — `[-_-]` yellow on success, `[O_O]` red on failure, with inline git branch and dirty/staged indicators
- **Modular config** — focused files under `config/`, sourced in order by `.zshrc`
- **Smart completions** — cached compinit with fuzzy/approximate matching, autosuggestions from history + completion
- **Dev workspace** — `devterm` picks 1-3 projects and opens Claude Code + terminal per column in iTerm2
- **Split mode** — `devterm -s` opens 1-8 Claude Code panes in an optimal grid for parallel AI-assisted development
- **Auto-dependency management** — Homebrew and zsh plugins installed automatically on first shell open
- **Startup splash** — randomized ASCII art + system stats, no network calls
- **System monitoring** — `sysmon` launches an iTerm2 dashboard with btop and mactop
- **XDG-compliant** — config lives under `~/.config/zsh/`, not in `$HOME`
- **One-command install** — copies config files into place with automatic backup

## Quick Start

### Option 1: Homebrew (macOS)

```bash
brew tap shreyasugemuge/shelly
brew install shelly
shelly install
exec zsh
```

### Option 2: Git Clone

```bash
git clone https://github.com/shreyasugemuge/shelly.git ~/.dotfiles/zsh
cd ~/.dotfiles/zsh
./install.sh
exec zsh
```

> **Note:** `~/.dotfiles/zsh` is a conventional example location — you can clone to any path you prefer (e.g., `~/shelly`, `~/.config/shelly`). The install script copies config files into place. Re-run `install.sh` to update from repo.

Preview without making changes:

```bash
./install.sh --dry-run
```

## Prerequisites

- **zsh** — included on macOS; `sudo apt install zsh` on Ubuntu/WSL; `sudo dnf install zsh` on Fedora; `sudo pacman -S zsh` on Arch
- **git** — for prompt branch/status info
- **curl** — for network aliases

Dependencies (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`) and CLI tools (`tree`) are installed automatically on first launch via your platform's package manager (Homebrew, apt, dnf, or pacman).

## File Structure

```
.
├── .zshrc                  Entry point — sources all modules
├── config/
│   ├── deps.zsh            Auto-installs Homebrew, plugins, and CLI tools
│   ├── environment.zsh     Exports, locale, zsh options, NVM setup
│   ├── prompt.zsh          Custom prompt with face + git integration
│   ├── aliases.zsh         Aliases organized by category
│   ├── functions.zsh       Utility functions + devterm workspace
│   ├── plugins.zsh         Plugin loading (autosuggestions, syntax highlighting)
│   ├── monitor.zsh         System monitor dashboard (sysmon command)
│   └── sysinfo.zsh         Neofetch-style startup splash screen
├── install.sh              Setup script (copies config + backup)
├── VERSION                 Current version number
├── CHANGELOG.md            Release history
├── CONTRIBUTING.md         How to contribute and release
├── LICENSE                 MIT License
└── archive/                Original bash config (v0.3.0, preserved)
```

## Prompt

```
[-_-] (main) user@host ~/projects/myapp
$
```

| Element     | Color   | Meaning                          |
|-------------|---------|----------------------------------|
| `[-_-]`     | yellow  | Last command succeeded            |
| `[O_O]`     | red     | Last command failed               |
| `(main)`    | green   | Git branch                        |
| `*` / `+`   | orange  | Unstaged / staged changes         |
| `?`         | orange  | Untracked files                   |
| `user@host` | gray    | Username and hostname (muted)     |
| `~/path`    | default | Current directory (auto-truncated)|

Branch section is hidden outside git repositories.

## System Monitor

`sysmon` launches an iTerm2 tab with btop (left) and mactop (right).

> **Requires** iTerm2 with Python API enabled: Preferences → General → Magic → Enable Python API

```
┌──────────────────────────┬──────────────────────┐
│                          │                      │
│  btop                    │  mactop              │
│  CPU cores + memory      │  CPU/GPU temp        │
│  + network               │  Power draw          │
│                          │  Frequency           │
│                          │  ANE + thermals      │
│                          │                      │
└──────────────────────────┴──────────────────────┘
```

| Command         | Description                            |
|-----------------|----------------------------------------|
| `sysmon`        | Launch or focus existing tab           |
| `sysmon kill`   | Close the sysmon tab                   |
| `sysmon status` | Check installed tools and tab state    |
| `sysmon help`   | Quick reference                        |
| `sysmon-old`    | Legacy layout (nvtop + macmon)         |

btop config is force-written on every launch for consistency. mactop auto-detects Apple Silicon — no config needed. Inactive pane dimming is disabled while sysmon is open.

## Dev Workspace

`devterm` launches an iTerm2 tab for multi-project development with Claude Code.

> **Requires** iTerm2 with Python API enabled: Preferences → General → Magic → Enable Python API

### Standard Mode

Pick 1-3 projects from your code folder. Each project gets a column with Claude Code (80%) on top and a terminal (20%) on the bottom.

```
┌──────────────────┬──────────────────┬──────────────────┐
│ claude :: proj1  │ claude :: proj2  │ claude :: proj3  │
│                  │                  │                  │
│  Claude Code     │  Claude Code     │  Claude Code     │
│  (80%)           │  (80%)           │  (80%)           │
│                  │                  │                  │
├──────────────────┼──────────────────┼──────────────────┤
│ terminal :: proj1│ terminal :: proj2│ terminal :: proj3│
│  (20%)           │  (20%)           │  (20%)           │
└──────────────────┴──────────────────┴──────────────────┘
```

Append `y` to a project number to launch Claude Code with `--dangerously-skip-permissions` (yolo mode). For example, entering `1y 3` opens project 1 in skip-permissions mode and project 3 normally. Yolo panes show `⚡ claude :: project` in the title.

| Command          | Description                               |
|------------------|-------------------------------------------|
| `devterm`              | Pick projects and launch                  |
| `devterm kill`         | Close the devterm tab                     |
| `devterm status`       | Check tab state                           |
| `devterm config`       | Show or change the code directory          |
| `devterm config reset` | Reset to default (auto-detect)             |
| `devterm help`         | Quick reference                           |

### Split Mode

`devterm -s` opens a single project with 1-8 Claude Code panes in an optimal grid layout. Every pane runs `claude --dangerously-skip-permissions`.

```
Grid layouts:
  1 → full    2 → [2]      3 → [3]      4 → [2x2]
  5 → [2+2+1] 6 → [3x3]   7 → [3+3+1]  8 → [4x4]
```

| Command              | Description                                    |
|----------------------|------------------------------------------------|
| `devterm -s`         | Pick a project and launch split grid           |
| `devterm -s -c`      | Use current directory (skip project picker)     |
| `devterm -s kill`    | Close the split tab                            |
| `devterm -s status`  | Check split tab state                          |
| `devterm -s help`    | Show split mode help                           |

Standard devterm and split mode have separate state — they can coexist.

### Configuration

The code directory defaults to `~/code`. If it doesn't exist, devterm auto-detects directories with git repos (`~/projects`, `~/dev`, `~/src`, etc.) and presents a picker.

| Command              | Description                                    |
|----------------------|------------------------------------------------|
| `devterm config`       | Show current directory, option to change       |
| `devterm config reset` | Remove saved directory, revert to auto-detect  |

You can also set `DEVTMUX_DIR` directly in `~/.zshrc.local`. The `devterm config` command manages this for you.

`devtmux` still works as a deprecation shim redirecting to `devterm`.

## Aliases & Functions

**Aliases** — `..`, `ll`, `refresh`, `zshrc`, `myip`, `gs`, `gb`, `gco`, `gsw`, `tre`, `yell`, and more. See [`config/aliases.zsh`](config/aliases.zsh).

**Functions** — `pan` (man page as PDF), `mkcd`, `extract` (any archive), `whichip`, `weather`, `portfind`, `cc` (Claude Code with notification), `ccnotify`, `iterm-setup`, `devterm`, `sysmon`. See [`config/functions.zsh`](config/functions.zsh) and [`config/monitor.zsh`](config/monitor.zsh).

## Customization

- **Local overrides**: `~/.zshrc.local` — machine-specific, not tracked by git
- **Add aliases/functions**: edit the appropriate file in `config/`
- **Change colors**: prompt colors in `config/prompt.zsh` using `%F{color}`

## Uninstall

```bash
./install.sh --uninstall
```

## Versioning

Follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for release history and [CONTRIBUTING.md](CONTRIBUTING.md) for the release process.

## License

[MIT](LICENSE) — Shreyas Ugemuge, 2017-2026
