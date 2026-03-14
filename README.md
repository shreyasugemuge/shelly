# Shelly

[![Version](https://img.shields.io/badge/version-4.2.0-blue.svg)](CHANGELOG.md)
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
- **Auto-dependency management** — Homebrew and zsh plugins installed automatically on first shell open
- **Startup splash** — randomized ASCII art + system stats, no network calls
- **System monitoring** — `sysmon` launches an iTerm2 dashboard with btop, nvtop, and macmon
- **XDG-compliant** — config lives under `~/.config/zsh/`, not in `$HOME`
- **One-command install** — backs up existing configs, symlinks everything into place

## Quick Start

```bash
git clone https://github.com/shreyasugemuge/shelly.git ~/.dotfiles/zsh
cd ~/.dotfiles/zsh
./install.sh
exec zsh
```

> **Note:** `~/.dotfiles/zsh` is a conventional example location — you can clone to any path you prefer (e.g., `~/shelly`, `~/.config/shelly`). The install script symlinks config files into place dynamically.

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
│   ├── functions.zsh       Utility functions (extract, mkcd, pan, etc.)
│   ├── plugins.zsh         Plugin loading (autosuggestions, syntax highlighting)
│   ├── monitor.zsh         System monitor dashboard (sysmon command)
│   └── sysinfo.zsh         Neofetch-style startup splash screen
├── install.sh              Setup script (symlinks + backup)
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
| `[-_-]`     | yellow  | Last command succeeded           |
| `[O_O]`     | red     | Last command failed              |
| `(main)`    | green   | Git branch                       |
| `*` / `+`   | orange  | Unstaged / staged changes        |
| `user@host` | gray    | Username and hostname (muted)    |
| `~/path`    | default | Current directory                |

Branch section is hidden outside git repositories.

## System Monitor

`sysmon` launches an iTerm2 dashboard. Auto-installs all tools on first run.

> **Requires** iTerm2 with Python API enabled: Preferences → General → Magic → Enable Python API

```
┌──────────────┬──────────┐
│              │  nvtop   │
│  btop        │  GPU %   │
│  CPU+mem+net │  VRAM    │
│              ├──────────┤
│              │  macmon  │
│              │  Temp    │
│              │  Power   │
└──────────────┴──────────┘
```

| Pane               | Tool   | Shows                              |
|--------------------|--------|------------------------------------|
| Left (60%)         | btop   | All CPU cores + memory + network   |
| Top-right          | nvtop  | GPU utilization % + VRAM bar       |
| Bottom-right       | macmon | CPU/GPU temp + power + frequency   |

| Command         | Description                             |
|-----------------|-----------------------------------------|
| `sysmon`        | Launch or focus existing window         |
| `sysmon kill`   | Close the iTerm2 window                 |
| `sysmon status` | Check installed tools and window state  |
| `sysmon help`   | Quick reference                         |

btop and nvtop configs are force-written on every launch for consistency. On Apple Silicon, nvtop's N/A fields are hidden automatically; macmon provides the thermal/power data that nvtop can't.

## Dev Workspace

`devterm` launches an iTerm2 workspace for multi-project development.

> **Requires** iTerm2 with Python API enabled: Preferences → General → Magic → Enable Python API

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

| Command          | Description                               |
|------------------|-------------------------------------------|
| `devterm`        | Pick projects and launch                  |
| `devterm kill`   | Close the iTerm2 window                   |
| `devterm status` | Check window state                        |
| `devterm help`   | Quick reference                           |

Pane titles show `claude :: project` (top) and `terminal :: project` (bottom). Claude pane titles are locked so Claude Code can't override them. Panes are resized to 80/20 via the iTerm2 Python API.

Append `y` to a project number to launch Claude Code with `--dangerously-skip-permissions` (yolo mode). For example, entering `1y 3` opens project 1 in skip-permissions mode and project 3 normally. Yolo panes show `⚡ claude :: project` in the title.

Set `DEVTMUX_DIR` to change the code folder (defaults to `~/code`).

`devtmux` still works as a shim that redirects to `devterm`.

## Aliases & Functions

**Aliases** — `..`, `ll`, `refresh`, `zshrc`, `myip`, `gs`, `gb`, `gco`, `gsw`, `tre`, `yell`, and more. See `config/aliases.zsh`.

**Functions** — `pan` (man page as PDF), `mkcd`, `extract` (any archive), `whichip`, `weather`, `portfind`, `cc` (Claude Code with notification), `ccnotify`, `iterm-setup`, `devterm`. See `config/functions.zsh`.

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

[MIT](LICENSE) — Shreyas Ugemuge, 2017–2026
