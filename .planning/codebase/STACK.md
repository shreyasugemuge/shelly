# Technology Stack

**Analysis Date:** 2026-03-14

## Languages

**Primary:**
- **zsh** — Entire configuration language. Used for all modules, functions, aliases, and scripting
- **bash** — Used only in `install.sh` and `deploy.sh` for POSIX compatibility and portability

## Runtime

**Environment:**
- **zsh** — Interactive shell (minimum: 5.0+, typically latest available via system package managers)
- **bash** — Installation and deployment scripts (POSIX-compatible, widely available)

**Package Manager:**
- **Homebrew** (macOS and Linux) — Primary package manager for installing Homebrew packages
- **apt** (Debian/Ubuntu/WSL) — Fallback for Linux systems
- **dnf** (Fedora/RHEL) — Fallback for Linux systems
- **pacman** (Arch/Manjaro) — Fallback for Linux systems
- **Lockfile:** Not applicable (no package manifest file; dependencies are managed via system package managers at runtime)

## Core Dependencies

**Required (runtime):**
- **git** — Git integration for prompt branch/status info, used in `config/prompt.zsh` and `config/sysinfo.zsh`
- **curl** — Network utilities for weather, IP lookup, and Homebrew installation. Used in `config/aliases.zsh`, `config/functions.zsh`, and `config/deps.zsh`

**Zsh Plugins (auto-installed):**
- **zsh-autosuggestions** — Fish-like ghost-text suggestions from history as you type. Installed automatically by `config/deps.zsh`
- **zsh-syntax-highlighting** — Real-time command syntax highlighting (green=valid, red=not found). Must be sourced last (requirement in `config/plugins.zsh`)

## System Monitor Tools (auto-installed by sysmon command)

**Core:**
- **tmux** — Terminal multiplexer. Creates the dashboard session. Installed by `_sysmon_ensure_deps()` in `config/monitor.zsh`
- **btop** — System resource monitor showing CPU cores (braille graphs), memory, and network. Force-written config at `~/.config/btop/btop.conf` on every sysmon launch
- **nvtop** — GPU monitor showing utilization % and VRAM. Only installed if GPU detected. Config auto-written to `~/.config/nvtop/interface.ini` on macOS

**Platform-specific:**
- **macmon** (macOS only) — Apple Silicon thermal/power monitor showing CPU/GPU temperature, power draw, and frequency. No sudo required. From Homebrew tap `vladkens/tap/macmon`. Installed by `_sysmon_ensure_deps()` in `config/monitor.zsh`

## Optional Dependencies

**Development:**
- **NVM** (Node Version Manager) — Lazy-loaded on first use of `nvm`, `node`, `npm`, or `npx` commands. Setup in `config/environment.zsh`. Searches for installation in standard locations (`/opt/homebrew/opt/nvm`, `/usr/local/opt/nvm`, `$HOME/.nvm`)

**Utilities (used by functions):**
- **lsof** — Used by `portfind()` function to find processes listening on ports
- **tree** — Used by `tre` alias for directory tree display (limit 2 levels)
- **figlet** — Used by `yell` alias for ASCII art text
- **fortune** — Optional: used in `config/sysinfo.zsh` for random quotes on startup (graceful fallback if missing)
- **man** (macOS) / **man-db** (Linux) — Used by `pan()` function to display man pages as PDFs in Preview

## Configuration Files

**Environment:**
- `.zshrc` — Entry point, sources all modules from `config/` in order
- `config/` directory containing:
  - `deps.zsh` — Dependency checker, auto-installer
  - `environment.zsh` — XDG directories, locale, NVM setup
  - `prompt.zsh` — Git-aware prompt with face indicator
  - `aliases.zsh` — Cross-platform aliases (with BSD/GNU detection for `ls`)
  - `functions.zsh` — Utility functions
  - `plugins.zsh` — zsh-autosuggestions and zsh-syntax-highlighting loading
  - `monitor.zsh` — sysmon dashboard orchestration
  - `sysinfo.zsh` — Startup splash screen with system stats

**Tool Configs (auto-generated):**
- `~/.config/btop/btop.conf` — Force-written by `config/monitor.zsh` on every sysmon launch. Shows CPU, memory, network; hides disks and process table
- `~/.config/nvtop/interface.ini` — Force-written by `config/monitor.zsh` on macOS to hide N/A fields (clock rate, temperature, fan speed, power) that Metal API doesn't support on Apple Silicon
- `~/.config/zsh/` — XDG config directory where symlinked modules live (created by `install.sh`)
- `~/.cache/zsh/` — Cache directory for completion dump and dependency check timestamps

**User-local (not tracked):**
- `~/.zshrc.local` — Machine-specific overrides, sourced at end of `.zshrc` if present

## Build & Deployment

**Installation:**
- `install.sh` — Bash script that backs up existing configs, creates symlinks from `config/` to `~/.config/zsh/`, and offers `--dry-run` and `--uninstall` modes

**Deployment:**
- `deploy.sh` — Bash script for pushing to git, tagging releases, and creating GitHub releases. Reads version from `VERSION` file

**Version Management:**
- `VERSION` file — Single source of truth for semantic version (currently `2.1.0`)
- `CHANGELOG.md` — Release history, updated manually on each version bump

## Platform Support

**Tested:**
- **macOS** (M-series and Intel) — Primary development target. Feature complete (btop, nvtop, macmon)
- **Linux** (Ubuntu, Fedora, Arch, WSL) — Full feature parity except macmon (platform-specific)

**Platform Detection:**
- Uses `[[ "$OSTYPE" == darwin* ]]` for macOS detection
- Uses `[[ "$OSTYPE" == linux* ]]` for Linux detection
- Package manager selection via `command -v` checks in this order: Homebrew → apt → dnf → pacman

**Shell Features Used:**
- `setopt` (zsh options: AUTO_CD, EXTENDED_GLOB, HIST_IGNORE_DUPS, SHARE_HISTORY, etc.)
- `compinit` (completion system with daily cache)
- `vcs_info` (zsh module for git integration)
- `precmd_functions` (hooks for prompt setup)
- `bindkey` (key binding configuration)

---

*Stack analysis: 2026-03-14*
