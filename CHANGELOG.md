# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.12.1] - 2026-04-11

### Fixed
- **compinit cache not persisting** — `compinit -d` only rewrites the zcompdump when completions change, leaving a stale mtime that caused every shell to rescan completions instead of using the cached path

## [4.12.0] - 2026-03-31

### Added
- **`comfy-monitor` dashboard overhaul** — full-featured ComfyUI monitoring dashboard with live system metrics, workflow details, and job tracking
  - **3-column system view** — memory (system + PyTorch), CPU & process (PID, RSS, uptime), storage & queue side by side
  - **Phase timeline bar** — colored visual showing time in loading (yellow), sampling (cyan), post-process (magenta) with percentages
  - **Overall job progress** — estimates total completion factoring in loading + sampling remaining + post-process
  - **Workflow metadata** — model name, resolution, frames, steps, sampler, scheduler, CFG, seed, LoRAs, prompt preview, workflow type badges (I2V/T2V/IMG/VID)
  - **Human-readable node descriptions** — plain-English explanation of what each node is doing
  - **Sampling progress** — per-step sparkline, throughput (Mpx/s, frames/s), ETA with finish time
  - **Completion summary** — phase breakdown with visual bars, top 3 bottleneck nodes, step timing stats
  - **Idle time tracking** — shows time idle between jobs and total idle this session
  - **Job history table** — recent jobs with ID, type, status, duration, model, size, output count
  - **Recent outputs** — newest output files with size and age
  - **Server log tail** — last 5 ComfyUI log entries
  - **Pending queue** — queued jobs with workflow type and model info
  - **Connection health** — WebSocket activity indicator, API latency, auto-reconnect with backoff
  - **CPU monitoring** — system CPU gauge with trend sparkline, ComfyUI process stats
  - **Disk usage** — free space and output directory size
- **`scripts/` directory** — bundled scripts installed to `~/.config/zsh/scripts/`; `comfy-monitor` now ships with Shelly instead of depending on an external script

### Changed
- **`comfy-monitor` alias** — now points to bundled `scripts/comfy_monitor.py` instead of external ComfyUI workflow script; still requires ComfyUI's venv for the `websockets` dependency
- **`install.sh`** — copies `scripts/` directory to `~/.config/zsh/scripts/` during install

## [4.11.0] - 2026-03-31

### Added
- **`claude` alias** — wraps Claude Code with `caffeinate -disu` to prevent display sleep during sessions
- **`comfy-monitor` alias** — conditional alias for ComfyUI Live Monitor dashboard; only defined when ComfyUI is installed. Configurable via `SHELLY_COMFY_DIR`

## [4.10.0] - 2026-03-31

### Added
- **Homebrew support** — `brew tap shreyasugemuge/shelly && brew install shelly` installs Shelly via Homebrew tap; `shelly install` activates the zsh config
- **`bin/shelly` CLI wrapper** — subcommands: `install`, `uninstall`, `version`, `update`, `help`
- **Homebrew formula** — `Formula/shelly.rb` downloads release tarball, installs to `share/shelly/`, exposes `bin/shelly` on PATH

### Changed
- **install.sh** — respects `SHELLY_ROOT` environment variable for Homebrew compatibility; existing `git clone && ./install.sh` workflow unchanged

## [4.9.0] - 2026-03-31

### Added
- **Shared iTerm2 utility layer** (`config/iterm2.zsh`) — `_iterm2_tab_exists`, `_iterm2_focus_tab`, `_iterm2_close_tab` consolidate 12 duplicated tab management functions into 3 parameterized ones; `$_SHELLY_IT2API` replaces hardcoded paths
- **Dedicated config modules** — `config/devterm.zsh` (dev workspace), `config/release.zsh` (shelly CLI) split out from the 1247-line `config/functions.zsh` monolith; `functions.zsh` now contains only utility functions (117 lines)
- **Configurable defaults** — `SHELLY_IT2API`, `SHELLY_DEVTERM_RATIO`, `SHELLY_CODE_DIRS` overridable in `~/.zshrc.local`
- **Full test suite** — 139 tests via bats-core covering all config modules: syntax checks, sourcing smoke tests, function unit tests, semver parsing, grid layout, iTerm2 hierarchy regex, mocked external commands
- **CI pipeline** (`.github/workflows/test.yml`) — automated tests, shellcheck linting, and syntax checks on push/PR
- **Test runner** (`tests/run`) — run all tests, specific files, or filter by pattern

### Changed
- **`config/monitor.zsh`** — extracted `_sysmon_write_btop_conf()` and `_sysmon_disable_dimming()` shared helpers; eliminated verbatim btop config duplication between sysmon and sysmon-old
- **`config/functions.zsh`** — reduced from 1247 to 117 lines (utilities only: pan, mkcd, extract, whichip, weather, portfind, cc, ccnotify, iterm-setup)
- **`.zshrc` source order** — now includes iterm2.zsh, release.zsh, devterm.zsh in the correct dependency order
- **Documentation** — updated README (version badge, file structure, macOS-only note, configurable defaults), CONTRIBUTING.md (automated release process), CLAUDE.md (new file layout and design decisions)

## [4.8.1] - 2026-03-28

### Changed
- **ccnotify** — layered iTerm2 notifications: OSC 9 banner + `RequestAttention=once` dock bounce for reliable multi-pane awareness
- **cc wrapper** — notification now includes project name (e.g. "Claude done — shelly")
- **notify-done.sh hook** — switched from `osascript` to `terminal-notifier` for native Notification Center integration; removed iTerm2-focused guard that suppressed all notifications during multi-pane work; added project name and click-to-activate iTerm2; grouped by project

## [4.8.0] - 2026-03-28

### Added
- **devterm config** (`devterm config`) — show or change the code directory interactively; `devterm config reset` removes saved directory and reverts to auto-detect
- **Interactive directory picker** — when no code directory is configured and `~/code` doesn't exist, devterm auto-detects directories containing git repos (`~/projects`, `~/dev`, `~/src`, `~/repos`, `~/workspace`, `~/work`) and presents a numbered picker with repo counts
- **Persist updates** — `_dev_persist_dir` now updates `DEVTMUX_DIR` in place in `~/.zshrc.local` (previously only appended and skipped duplicates)

## [4.7.0] - 2026-03-28

### Added
- **devterm split cwd mode** (`devterm -s -c`) — skip the project picker and use the current working directory; only prompts for pane count (1-8)
- Updated help text for both `devterm help` and `devterm -s help` to document the `-c` flag

## [4.6.0] - 2026-03-28

### Added
- **devterm split mode** (`devterm -s`) — single-project, multi-Claude workspace with 1-8 equal-sized panes in an optimal grid layout; rows-first split strategy with Python API equalization; all panes run `claude --dangerously-skip-permissions`; separate state file from regular devterm

## [4.5.1] - 2026-03-21

### Changed
- **sysmon opens a tab, not a window** — `sysmon` and `sysmon-old` now create a new tab in the current iTerm2 window (via `it2api create-tab --window`) instead of spawning a separate window; `sysmon kill` closes only the sysmon tab, not the entire window
- **Renamed internals** — `_sysmon_window_exists` → `_sysmon_tab_exists`, `_sysmon_focus_window` → `_sysmon_focus_tab`, `_sysmon_close_window` → `_sysmon_close_tab` (and matching `_sysmon_old_*` variants); all user-facing strings updated from "window" to "tab"

## [4.5.0] - 2026-03-21

### Changed
- **devterm opens a tab, not a window** — `devterm` now creates a new tab in the current iTerm2 window (via `it2api create-tab --window`) instead of spawning a separate window; `devterm kill` closes only the devterm tab, not the entire window
- **Renamed internals** — `_dev_window_exists` → `_dev_tab_exists`, `_dev_focus_window` → `_dev_focus_tab`, `_dev_close_window` → `_dev_close_tab`; all user-facing strings updated from "window" to "tab"

## [4.4.1] - 2026-03-19

### Fixed
- **compinit insecure directory warning** — added `-u` flag to `compinit` calls to suppress the interactive prompt about group-writable Homebrew directories (common after `brew reinstall zsh-completions`)

## [4.4.0] - 2026-03-17

### Changed
- **sysmon overhaul** — replaced nvtop (mostly N/A on Apple Silicon) and macmon with mactop; sudoless, M4-confirmed, shows GPU util/freq, ANE, power draw, and thermals
- **mactop theme** — per-component color theme via force-written `~/.mactop/theme.json`
- **Legacy preserved** — old nvtop+macmon layout available as `sysmon-old`

## [4.3.0] - 2026-03-17

### Changed
- **Copy-based install** — `install.sh` now copies `.zshrc`, `config/`, and `VERSION` instead of symlinking; tools like iTerm2 can safely modify `~/.zshrc` without dirtying the repo; re-run `install.sh` to update from repo

## [4.2.1] - 2026-03-14

Startup performance and robustness — no new features.

### Fixed
- **Startup: brew --prefix cached** — computed once in `.zshrc` and reused across deps/plugins/completions (~100-200ms saved)
- **Startup: sysinfo cache** — hardware info (until reboot), package count (1h TTL), git streak (5m TTL) cached to `~/.cache/zsh/sysinfo_cache`; eliminates `system_profiler`, `brew list`, `git log` on most shell opens (~650-1400ms saved)
- **Git streak guard** — skip `git log` when `$HOME` has no `.git` directory
- **`local` declaration** — `environment.zsh` `local _default_node` → `local _default_node=""` (zsh typeset gotcha)
- **devterm pane guard** — `_dev_build_session` checks `col_sid` non-empty after vertical split; gracefully degrades to fewer columns

## [4.2.0] - 2026-03-14

Devterm full rebuild — pane resize, clean scrollback, locked titles, stale session cleanup.

### Fixed
- **Pane resize** — replaced broken `_dev_resize_pane` (single-session approach that failed silently) with `_dev_resize_layout`, which walks the tab's split tree via iTerm2 Python API and sets all horizontal splits to 80% Claude / 20% terminal
- **Clean scrollback** — devterm now uses a 3-phase build: create splits & navigate, resize, then `inject ClearScrollback` + launch Claude; no more visible `cd && clear && claude` flash in the Claude pane
- **Stale sessions** — `_dev_build_session` always closes any tracked window before creating a new one, preventing orphan panes from prior runs
- **`local` variable leak** — fixed bare `local var` declarations inside loops (`col_out`, `col_sid`, `term_out`, `term_sid` in functions.zsh; `ver` in monitor.zsh) that printed values to stdout on loop re-entry (zsh `typeset` behavior)

### Changed
- **Pane titles** — top panes show `claude :: project` (or `⚡ claude :: project` for yolo), bottom panes show `terminal :: project`; titles set via `inject` (invisible) and locked on Claude panes with `set-profile-property allow_title_setting false` so Claude Code cannot override
- **Removed badges** — large badge watermarks replaced by pane titles (cleaner in small panes)
- **Removed figlet** — terminal panes launch clean with just the project directory and title
- **sysmon robustness** — split-pane failures now checked (null session ID guards), btop launched via `send-text` instead of `--command` for reliable splitting, dimming save/restore on launch/kill

## [4.1.0] - 2026-03-14

iTerm2 shell integration, devterm badges, yolo indicators, worktree support, and Claude Code notification helpers.

### Added
- **iTerm2 shell integration** (`plugins.zsh`) — auto-sourced when present; run `iterm-setup` once to install; enables command marks (Cmd+Shift+↑/↓), semantic history, recent directories (Cmd+Opt+/)
- **devterm pane badges** — each project column gets an iTerm2 badge (top-right corner) showing the project name, visible through Claude Code
- **Yolo tab indicator** — panes launched with `y` suffix get a ⚡ YOLO tab title as a visual safety signal
- **Git worktree support** — devterm project picker now detects worktrees (`.git` file) alongside normal repos, shows `[wt]` marker and correct branch name
- **`ccnotify`** — sends an iTerm2 notification when called; use to signal task completion
- **`cc`** — wrapper around `claude` that fires `ccnotify` when Claude Code exits
- **`iterm-setup`** — one-time installer for iTerm2 shell integration (`~/.iterm2_shell_integration.zsh`)

## [4.0.1] - 2026-03-14

### Fixed
- **Non-iTerm graceful degradation** — `sysmon` and `devterm` now print a clear "non-iTerm mode" message (instead of failing/hanging) when run outside iTerm2; uses `$TERM_PROGRAM` check
- **iTerm2 gate before prompts** — iTerm2 check now runs before `_sysmon_ensure_deps` and before `devterm`'s interactive project picker, preventing wasted work in non-iTerm terminals

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

[Unreleased]: https://github.com/shreyasugemuge/shelly/compare/v4.12.1...HEAD
[4.12.1]: https://github.com/shreyasugemuge/shelly/compare/v4.12.0...v4.12.1
[4.12.0]: https://github.com/shreyasugemuge/shelly/compare/v4.11.0...v4.12.0
[4.11.0]: https://github.com/shreyasugemuge/shelly/compare/v4.10.0...v4.11.0
[4.10.0]: https://github.com/shreyasugemuge/shelly/compare/v4.9.0...v4.10.0
[4.9.0]: https://github.com/shreyasugemuge/shelly/compare/v4.8.1...v4.9.0
[4.8.1]: https://github.com/shreyasugemuge/shelly/compare/v4.8.0...v4.8.1
[4.8.0]: https://github.com/shreyasugemuge/shelly/compare/v4.7.0...v4.8.0
[4.7.0]: https://github.com/shreyasugemuge/shelly/compare/v4.6.0...v4.7.0
[4.6.0]: https://github.com/shreyasugemuge/shelly/compare/v4.5.1...v4.6.0
[4.5.1]: https://github.com/shreyasugemuge/shelly/compare/v4.5.0...v4.5.1
[4.5.0]: https://github.com/shreyasugemuge/shelly/compare/v4.4.1...v4.5.0
[4.4.1]: https://github.com/shreyasugemuge/shelly/compare/v4.4.0...v4.4.1
[4.4.0]: https://github.com/shreyasugemuge/shelly/compare/v4.3.0...v4.4.0
[4.3.0]: https://github.com/shreyasugemuge/shelly/compare/v4.2.1...v4.3.0
[4.2.1]: https://github.com/shreyasugemuge/shelly/compare/v4.2.0...v4.2.1
[4.2.0]: https://github.com/shreyasugemuge/shelly/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/shreyasugemuge/shelly/compare/v4.0.1...v4.1.0
[4.0.1]: https://github.com/shreyasugemuge/shelly/compare/v4.0.0...v4.0.1
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
