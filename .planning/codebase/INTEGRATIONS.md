# External Integrations

**Analysis Date:** 2026-03-14

## APIs & External Services

**Public IP Lookup:**
- **ipinfo.io** — REST API for querying public IP address
  - Used in: `config/aliases.zsh` (alias `globip`), `config/functions.zsh` (function `whichip()`)
  - Request: `curl -s --max-time 3 ipinfo.io/ip`
  - Timeout: 3 seconds (graceful timeout if service unavailable)
  - Auth: None (public endpoint)

**Weather:**
- **wttr.in** — Weather API providing 3-line format output
  - Used in: `config/functions.zsh` (function `weather()`)
  - Request: `curl -s --max-time 3 "wttr.in/${city}?format=3"`
  - Timeout: 3 seconds
  - Auth: None (public endpoint)
  - Usage: `weather` or `weather <city>` for current conditions

**Package Manager Install:**
- **Homebrew (GitHub)** — Bootstrap script for Homebrew installation if not present
  - Used in: `config/deps.zsh` (_install_plugins function)
  - Request: `curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`
  - Auth: None (public script)
  - Trigger: Automatic on first zsh shell open if Homebrew not found and macOS detected

## Version Control

**Git:**
- Used for: Branch tracking, dirty/staged status in prompt
- Integration point: `config/prompt.zsh` via zsh's `vcs_info` module
- Behavior: Non-destructive inspection only (no commits, pushes, or modifications)
- Performance: Lightweight untracked file check via `git status --porcelain`

## System-Level Integrations

**Process Monitoring:**
- **lsof** (List Open Files) — Used by `portfind()` function to find processes listening on specific ports
  - Command: `lsof -i :"$port"`
  - Platform: Unix/Linux standard

**Terminal Emulator Integration:**
- **Preview.app** (macOS only) — Used by `pan()` function to display man pages as PDFs
  - Command: `man -t command | open -f -a /Applications/Preview.app`
  - Platform: macOS only (graceful fallback on Linux with error message)

## Display & Rendering

**Terminal Environment Detection:**
- `tput` — Terminal info lookup used by `config/monitor.zsh` to get terminal dimensions for tmux session
  - Used in: `_sysmon_launch()` to set initial tmux window size

**System Profiler (macOS):**
- `system_profiler SPDisplaysDataType` — GPU detection in `config/monitor.zsh` and `config/sysinfo.zsh`
- `sysctl` — CPU model, RAM size, uptime calculation in `config/sysinfo.zsh`

**System Info (Linux):**
- `/proc/cpuinfo` — CPU model lookup in `config/sysinfo.zsh`
- `/proc/meminfo` — RAM total in `config/sysinfo.zsh`
- `/etc/os-release` — OS name and version in `config/sysinfo.zsh`
- `lspci` — GPU detection in `config/monitor.zsh` and `config/sysinfo.zsh`

## GitHub Integration

**Repository Hosting:**
- **GitHub** (`shreyasugemuge/shelly`) — Remote repository
- Integration points:
  - `deploy.sh` creates releases via GitHub CLI (`gh` commands)
  - README and CHANGELOG reference GitHub repo URLs
  - Install instructions clone from GitHub: `git clone https://github.com/shreyasugemuge/shelly.git`

**CI/CD & Releases:**
- Not currently detected in codebase. Releases are manual via `deploy.sh` → GitHub API

## Environment Configuration

**Required Environment Variables:**
- `OSTYPE` — Detected automatically by shell (darwin*, linux*, etc.)
- `HOME` — Standard user home directory
- `EDITOR` — Set in `config/environment.zsh` to `emacs` (fallback to `$VISUAL`)

**Optional Environment Variables:**
- `XDG_CONFIG_HOME` — Config directory (defaults to `~/.config`)
- `XDG_CACHE_HOME` — Cache directory (defaults to `~/.cache`)
- `XDG_DATA_HOME` — Data directory (defaults to `~/.local/share`)
- `LANGUAGE`, `LANG`, `LC_ALL` — Set to `en_US.UTF-8` in `config/environment.zsh`
- `NVM_DIR` — Node Version Manager directory (defaults to `~/.nvm`)
- `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` — Configured to `fg=245` in `config/plugins.zsh`

**Not Required (machine-local):**
- `.zshrc.local` — Optional file for machine-specific overrides (not tracked, not required)

## Secrets & Credentials

**Storage:**
- No secrets stored in codebase (all-public configuration)
- `.env` files are NOT used
- GitHub token: If using `gh` commands in `deploy.sh`, relies on `~/.config/gh/hosts.yml` or standard GitHub CLI auth (not in codebase)

**Security Model:**
- Configuration is stateless and credential-free
- All network calls use public APIs (no authentication required)
- System monitoring tools (btop, nvtop, macmon) run without elevated privileges (exception: apt/dnf/pacman may require sudo for package installation)

## Package Management via Homebrew

**Installation Method:**
- Homebrew is auto-detected and used as primary package manager via `brew` command
- Fallback package managers: apt (Debian/Ubuntu/WSL), dnf (Fedora), pacman (Arch)
- Packages auto-installed by `config/deps.zsh`:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- Packages auto-installed by `config/monitor.zsh` (sysmon):
  - `tmux`
  - `btop`
  - `nvtop` (if GPU detected)
  - `vladkens/tap/macmon` (macOS only, if GPU detected)

**Platform-Specific Tap:**
- `vladkens/tap/macmon` — Homebrew tap for macmon on macOS. Added dynamically by `config/monitor.zsh` on first sysmon run

## Webhooks & Callbacks

**Incoming:**
- None detected (this is a shell configuration, not a service)

**Outgoing:**
- None detected (shell configuration only performs local operations and API reads)

## Performance & Caching

**Completion Cache:**
- Location: `~/.cache/zsh/zcompdump`
- Regenerated: Once per day (checked via date comparison in `.zshrc`)
- Reduces startup time by caching zsh completion data

**Dependency Check Cache:**
- Location: `~/.cache/zsh/deps_checked`
- Regenerated: Once per day (timestamp comparison in `config/deps.zsh`)
- Prevents redundant plugin installation checks on every shell open

**Lazy Loading:**
- NVM is lazy-loaded on first use of `nvm`, `node`, `npm`, or `npx` commands (saves ~300ms startup time)
- Implemented in `config/environment.zsh` via stub functions that source NVM on first invocation

---

*Integration audit: 2026-03-14*
