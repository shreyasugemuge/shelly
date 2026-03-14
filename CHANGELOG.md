# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.0] - 2026-03-14

Replace tmux with iTerm2 native API for both sysmon and devterm. Rename devtmux to devterm.

### Added
- **iTerm2 Python API integration** — `sysmon` and `devterm` now use `it2api` (bundled with iTerm2) to create and manage windows/panes; requires iTerm2 with Python API enabled (Preferences → General → Magic → Enable Python API)
- **`devterm` command** — renamed from `devtmux`; same picker and yolo mode, now backed by iTerm2 instead of tmux
- **Window tracking** — session IDs persisted to `~/.cache/zsh/{sysmon,devterm}.session_id`; `sysmon`/`devterm` focus existing windows instead of relaunching

### Changed
- **`sysmon`** — launches an iTerm2 window instead of a tmux session; `sysmon kill` closes the window via AppleScript; `sysmon status` shows iTerm2 version instead of tmux
- **`devterm`** (was `devtmux`) — same multi-project layout (Claude Code top + figlet terminal bottom, 1-3 columns) but backed by iTerm2
- **`devterm status`** — simplified to show open/not open (pane list not available without tmux)
- **Removed tmux aliases** — `a_tmux`, `l_tmux`, `n_tmux` removed from `aliases.zsh`

### Removed
- **tmux dependency** — no longer required; sysmon and devterm are macOS/iTerm2-only features

### Deprecated
- **`devtmux`** — still works as a shim that redirects to `devterm`; will be removed in a future version

## [3.2.1] - 2026-03-14

devtmux enhancements and dependency management improvements.

### Added
- **devtmux yolo mode** — append `y` to a project number (e.g. `1y 3`) to launch Claude Code with `--dangerously-skip-permissions` for that project
- **figlet project banner** — bottom terminal panes now display the project name in large ASCII art via figlet
- **CLI tool dependency tracking** — `deps.zsh` now auto-installs required CLI tools (`figlet`, `tree`) alongside zsh plugins

### Changed
- **deps.zsh** — renamed `_install_plugins` to `_install_missing`; now handles both zsh plugins and CLI tools in a single pass

## [3.2.0] - 2026-03-14

Smarter completions with autosuggestions, remove fzf dependency.

### Added
- **zsh-autosuggestions** — fish-style ghost-text suggestions from history and completion engine; async mode, dim gray highlight, sourced before syntax-highlighting
- **Smarter completion matching** — approximate matching (allows 1 typo), file sort by modification time, ssh host completion from known_hosts/config, dedup args for rm/cp/mv/kill/diff

### Removed
- **fzf** — removed as a dependency; no longer auto-installed by `deps.zsh`
- **fzf-tab** — removed; tab completion uses native zsh `menu select` with enhanced matching
- **fzf shell integration** — `Ctrl-T`, `Ctrl-R`, `Alt-C` keybindings removed (were fzf-specific)

### Changed
- **devtmux project picker** — replaced fzf multi-select with numbered-list picker (no external dependencies)
- **Completion system** — native compinit with autosuggestions replaces fzf-tab; four-stage matcher (case-insensitive, partial-word, substring, approximate)
- **compdef registration** — moved from individual config files to `.zshrc` (after compinit)

## [3.1.1] - 2026-03-14

Bug fixes for devtmux and dependency checking.

### Fixed
- **devtmux project picker** — escaped glob-sensitive `(` in zsh parameter expansion, fixing "bad pattern" error when selecting projects
- **deps.zsh** — stamp file now written only after `_install_plugins` succeeds, preventing skipped retries on failure

## [3.1.0] - 2026-03-14

Fuzzy completion overhaul and dependency cleanup.

### Added
- **fzf as required dependency** — auto-installed by `deps.zsh`; used by devtmux project picker and fzf-tab completion
- **fzf-tab** — replaces default zsh tab completion with fzf-powered fuzzy matching and directory previews; auto-cloned from GitHub on first launch
- **fzf shell integration** — `Ctrl-T` (files), `Ctrl-R` (history), `Alt-C` (cd) keybindings via `source <(fzf --zsh)`

### Changed
- **devtmux project picker** — fzf is now required (no more numbered-list fallback)
- **Completion system** — replaced `zsh-autosuggestions` (ghost-text) with `fzf-tab` (fuzzy matching with previews on Tab)

### Removed
- **zsh-autosuggestions** — replaced by fzf-tab; uninstalled from system
- **deploy.sh** — removed (manual tag+push workflow is sufficient)

## [3.0.0] - 2026-03-14

Dynamic dev workspace, quality hardening, and enhanced completions.

### Added
- **`devtmux` command** (`config/functions.zsh`) — dynamic multi-project tmux workspace; pick 1-3 projects from `~/code` via fzf, opens Claude Code + terminal per column; subcommands: `kill`, `status`, `help`
- **Tab completion** for `devtmux` and `sysmon` subcommands (kill, stop, status, info, help)
- **Enhanced zsh completion system** — `zsh-completions` plugin for extra completions (brew, docker, git, etc.); partial/fuzzy matching, colored output, process-aware kill completion, and XDG-compliant completion cache
- **Input validation** — `portfind` validates port range (1-65535), `mkcd` rejects empty args
- **Shellcheck zero-warning baseline** — all `config/*.zsh` files pass shellcheck with documented inline suppressions
- **Plugin sourcing order guard** — comment block in `plugins.zsh` warning that `zsh-syntax-highlighting` must be sourced last

### Changed
- **Platform detection centralized** — `IS_MACOS`/`IS_LINUX` set once in `.zshrc`, replacing 11 scattered `$OSTYPE` checks across config modules
- **PATH deduplication** — `typeset -U path` in `environment.zsh` ensures no duplicate PATH entries
- **Completion matching** — upgraded from simple case-insensitive to multi-strategy: case-insensitive, partial-word, substring

### Security
- **Secrets audit** — confirmed zero credentials, IPs, or machine-specific paths in tracked config files
- **SC2155 fixes** — separated declaration and assignment to prevent masking return values

## [2.1.0] - 2026-03-07

Cross-platform support — shelly now works on macOS, Linux, and WSL out of the box.

### Added
- **Cross-platform plugin loading** — `plugins.zsh` searches Homebrew, `/usr/share`, and `/usr/local/share` for zsh plugins, working with any package manager
- **Cross-platform dependency installation** — `deps.zsh` detects apt, dnf, pacman, or Homebrew and installs missing plugins via the native package manager
- **Expanded install hints** — `install.sh` now shows instructions for macOS, Ubuntu/Debian, Fedora, Arch, and WSL

### Changed
- **`fanboost` alias** moved to `~/.zshrc.local` (machine-specific, not tracked)

## [2.0.0] - 2026-03-07

### Added
- **`fanboost` alias** — shortcut to `~/Comfy/fan_boost.sh` for quick fan control

## [1.3.3] - 2026-02-20

Thermal monitoring with macmon — the missing piece for Apple Silicon.

### Added
- **macmon pane** — bottom-right pane showing CPU/GPU temperature, power draw, and frequency in real-time; no sudo required, uses Apple's private APIs via Rust
- **Auto-install macmon** — `vladkens/tap/macmon` installed via Homebrew on first `sysmon` run (macOS only)
- **3-pane layout** — btop (left 60%) + nvtop (top-right) + macmon (bottom-right); macmon fills the gap left by nvtop's N/A temperature/power fields on Apple Silicon

### Changed
- **`sysmon status`** — now shows macmon version and install state
- **`sysmon help`** — now lists macmon pane description

## [1.3.2] - 2026-02-20

Lean two-pane dashboard with clean configs.

### Changed
- **`sysmon` layout** — removed bandwhich (bottom strip) entirely; dashboard is now a clean two-pane split: btop (left 60%) + nvtop (right 40%)
- **btop config** — force-written on every launch with `shown_boxes = "cpu mem net"` (removed disks and process table); all CPU cores get maximum space with braille graphs
- **nvtop config** — force-written on every launch (macOS only) to hide all broken Apple Silicon N/A fields (GPU/MEM clock, temperature, fan speed, power, encoder/decoder, PCIe TX/RX); keeps only GPU % chart, VRAM bar, and trimmed process list (PID, GPU%, VRAM, command)

### Removed
- **bandwhich** — no longer installed or used by sysmon; per-process network bandwidth pane removed from dashboard

## [1.3.1] - 2026-02-20

Config cleanup and documentation.

### Fixed
- **`sysmon` now force-deletes stale btop/nvtop configs on every launch** — removes `~/.config/btop/btop.conf` and `~/.config/nvtop/interface.ini` before starting the dashboard, ensuring tools always launch with their defaults and no leftover config from previous experiments silently changes the layout

### Added
- **`CLAUDE.md`** — comprehensive sysmon section with architecture, Apple Silicon limitations, 6 development retrospectives (btop --conf hallucination, config file pollution, sudo in tmux, nvtop N/A fields, failed tool replacements, git lock files in sandbox)
- **Known Issues** documented in CHANGELOG and README for nvtop Apple Silicon gaps and bandwhich sudo behavior

## [1.3.0] - 2026-02-19

System monitoring dashboard, neofetch-style splash, and repo cleanup.

### Added
- **`sysmon` command** (`config/monitor.zsh`) — one-command system monitoring dashboard using tmux with btop (CPU/RAM/disk), nvtop (GPU), and bandwhich (per-process network bandwidth); auto-installs all prerequisites via brew/apt/dnf/pacman

### Known Issues
- **nvtop on Apple Silicon**: GPU %, VRAM bar, and process-level GPU % work; everything else (clock rates, temperature, fan speed, power draw, PCIe TX/RX, per-process GPU MEM/CPU) shows N/A — this is an Apple Metal API limitation, not a bug
- **bandwhich needs sudo**: the bottom tmux pane may show a password prompt on macOS; click into it and enter your password

### Changed
- **Startup splash** (`config/sysinfo.zsh`) — replaced plain text dashboard with a neofetch-style splash screen: randomized ASCII art side-by-side with system stats, uptime, package count, git commit streak, and optional fortune quote; removed network calls from startup (use `myip` instead)
- **`archive/.bashrc`** — scrubbed hardcoded MongoDB password, EC2 IPs, SSH keys, university credentials, and user-specific paths
- **`CONTRIBUTING.md`** — fixed branch name `main` → `master`
- **`README.md`** — added sysmon documentation, updated file structure tree with monitor.zsh, deploy.sh, and CLAUDE.md

## [1.2.1] - 2026-02-17

Tone down colors — let syntax highlighting do its job.

### Changed
- **Prompt**: user@host now dim gray, directory path now default terminal color; removed magenta, light blue, and cyan from static prompt elements — color reserved for meaningful indicators (face status, git state)
- **Startup dashboard**: section headers (`── System ──`, `── Network ──`) changed from cyan to dim gray; hostname no longer bold; removed all decorative color variables

### Added
- **`CLAUDE.md`** — project context file documenting repo layout, color philosophy, design decisions, versioning process, and gotchas

## [1.2.0] - 2026-02-17

Auto-dependency management and startup system/network dashboard.

### Added
- **`config/deps.zsh`** — automatic dependency checker that runs once per day; installs Homebrew itself if missing, then installs any missing zsh plugin formulae
- **`config/sysinfo.zsh`** — startup dashboard showing system specs (OS, CPU, GPU, RAM) and network info (public IP, local IP, Wi-Fi SSID, DNS) on every interactive shell open
- Dynamic `brew --prefix` lookups in `plugins.zsh` — no more hardcoded `/opt/homebrew` paths, works on both Apple Silicon and Intel Macs

### Changed
- `.zshrc` module load order now includes `deps.zsh` first and `sysinfo.zsh` last
- `plugins.zsh` uses `$(brew --prefix)` instead of hardcoded Homebrew paths
- `install.sh` dry-run output now mentions automatic dependency installation

## [1.1.0] - 2026-02-16

Performance, robustness, and quality-of-life improvements across the board.

### Added
- **Lazy-loaded NVM** — stub functions for `nvm`, `node`, `npm`, `npx` defer sourcing until first use, saving ~300ms on every shell startup
- **Cached `compinit`** — completion dump regenerated once per day instead of every shell start
- **Untracked file indicator** — git prompt now shows `?` (orange) when untracked files exist
- **Path truncation** — deep paths auto-shorten (e.g., `~/…/foo/bar/baz` instead of full path)
- **`portfind <port>`** function — find what's listening on a given port via `lsof`
- **`tre`** alias — `tree -C -L 2` for quick, colorized directory overview
- **`gb`** alias — `git branch`
- **`gco`** alias — `git checkout`
- **`gsw`** alias — `git switch`
- **`zsh-bench`** alias — `time zsh -i -c exit` for startup benchmarking

### Changed
- `globip` alias — added `--max-time 3` to `curl` to prevent hanging when offline
- `whichip()` function — added `--max-time 3` to `curl`
- `weather()` function — added `--max-time 3` to `curl`
- `locip` alias — detects active network interface via `route get default` instead of hardcoding `en0`
- `whichip()` function — detects active interface with fallback to `en0`

## [1.0.0] - 2026-02-16

Complete rewrite from Bash to Zsh. This is a breaking change from all previous versions.

### Added
- Modular zsh configuration with XDG Base Directory compliance
- Custom prompt with signature face indicator (`-_-` / `O_O`) and git integration
- Git branch and dirty/staged status display via `vcs_info`
- Modern 256-color palette (yellow/red faces, green git, magenta user, cyan path)
- `install.sh` with backup, symlink, `--dry-run`, and `--uninstall` support
- `config/environment.zsh` — exports, locale, zsh options, conditional NVM loading
- `config/prompt.zsh` — two-line prompt with face, git info, user, host, directory
- `config/aliases.zsh` — organized aliases (file ops, git, network, tmux, typo fixes)
- `config/functions.zsh` — utility functions: `pan`, `mkcd`, `extract`, `whichip`, `weather`
- Support for `~/.zshrc.local` machine-specific overrides
- Comprehensive README with install guide, prompt reference, and troubleshooting
- Proper `.gitignore` for OS files, editor artifacts, secrets, and zsh runtime files
- `CHANGELOG.md`, `VERSION`, `LICENSE`, and `CONTRIBUTING.md`

### Removed
- Monolithic `.bashrc` (archived to `archive/`)
- Hardcoded MongoDB credentials
- Hardcoded EC2 IP addresses and SSH key references
- University/college-specific aliases and paths (fit.edu, SUBMITSERVER, CANVAS)
- `.bash_net` network mode and all references
- Stale script references (`~/scripts/*.sh`)
- DynamoDB local alias
- Java aliases
- Rediffmail and GMAIL SMTP script aliases
- All hardcoded user-specific paths (`/Users/shreyasugemuge/...`)

### Changed
- Shell: Bash → Zsh (macOS default since Catalina)
- Config structure: single file → modular `config/` directory
- Prompt: ANSI escape codes → native zsh `%F{color}` expansion
- History: basic → deduplicated, shared, incremental append
- Completion: none → zsh `compinit` with case-insensitive matching
- `refresh` alias: `source ~/.bashrc` → `exec zsh`
- `locip` alias: `ifconfig` parsing → `ipconfig getifaddr en0` (macOS native)
- `rm` alias: `rm -ir` → `rm -i` (interactive without recursive by default)

## [0.3.0] - 2017-04-14

Legacy bash configuration. Last version before the zsh rewrite.

### Features (as archived)
- Custom bash prompt with exit-code face indicator
- SSH aliases for EC2 instances and university servers
- Network utility aliases (globip, locip, myip)
- Tmux session management aliases
- `updaterc()` function for pushing config changes to git
- `.bash_net` alternate "network mode" prompt
- Java, DynamoDB, and GMAIL SMTP helpers
- Figlet/cowsay terminal greetings

### Known Issues
- Hardcoded credentials in plaintext
- Hardcoded paths specific to one machine
- References to scripts not included in repo
- `.bash_net` mode with duplicated alias definitions
- `$CANVAS` variable used but never defined

## [0.2.0] - 2017-03-xx

### Added
- Network mode (`.bash_net`)
- College course directory shortcuts
- Submit server and Canvas aliases

## [0.1.0] - 2017-02-xx

### Added
- Initial `.bashrc` with custom prompt
- Basic aliases (ls, cd, rm)
- SSH alias for university server
- Figlet greeting

---

[Unreleased]: https://github.com/shreyasugemuge/shelly/compare/v4.0.0...HEAD
[4.0.0]: https://github.com/shreyasugemuge/shelly/compare/v3.2.1...v4.0.0
[3.2.1]: https://github.com/shreyasugemuge/shelly/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/shreyasugemuge/shelly/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/shreyasugemuge/shelly/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/shreyasugemuge/shelly/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/shreyasugemuge/shelly/compare/v2.1.0...v3.0.0
[2.1.0]: https://github.com/shreyasugemuge/shelly/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/shreyasugemuge/shelly/compare/v1.3.3...v2.0.0
[1.3.3]: https://github.com/shreyasugemuge/shelly/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/shreyasugemuge/shelly/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/shreyasugemuge/shelly/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/shreyasugemuge/shelly/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/shreyasugemuge/shelly/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/shreyasugemuge/shelly/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/shreyasugemuge/shelly/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shreyasugemuge/shelly/compare/v0.3.0...v1.0.0
[0.3.0]: https://github.com/shreyasugemuge/shelly/releases/tag/v0.3.0
[0.2.0]: https://github.com/shreyasugemuge/shelly/releases/tag/v0.2.0
[0.1.0]: https://github.com/shreyasugemuge/shelly/releases/tag/v0.1.0