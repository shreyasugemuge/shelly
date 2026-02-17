# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/shreyas613/bash_old/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/shreyas613/bash_old/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/shreyas613/bash_old/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/shreyas613/bash_old/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shreyas613/bash_old/compare/v0.3.0...v1.0.0
[0.3.0]: https://github.com/shreyas613/bash_old/releases/tag/v0.3.0
[0.2.0]: https://github.com/shreyas613/bash_old/releases/tag/v0.2.0
[0.1.0]: https://github.com/shreyas613/bash_old/releases/tag/v0.1.0
