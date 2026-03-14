# Architecture

**Analysis Date:** 2026-03-14

## Pattern Overview

**Overall:** Modular zsh configuration framework with layered initialization

**Key Characteristics:**
- Single entry point (`.zshrc`) that sources config modules in strict order
- Each module is independently functional and focused on one concern
- Platform detection (macOS/Linux/WSL) throughout with fallbacks
- Lazy-loading for expensive operations (NVM)
- Stateful single commands (`sysmon`) that manage complex subprocesses (tmux)

## Layers

**Entry Point Layer:**
- Purpose: Bootstrap the shell configuration, establish version tracking, source modules in correct order
- Location: `/.zshrc`
- Contains: Version reading, module sourcing loop, history setup, completion caching, key bindings, local overrides
- Depends on: None (root)
- Used by: zsh shell initialization

**Dependency Management Layer:**
- Purpose: Ensure required zsh plugins are installed before they're sourced
- Location: `/config/deps.zsh`
- Contains: Plugin detection, platform-specific package manager invocation, once-per-day caching
- Depends on: None (must run first)
- Used by: All plugin-dependent layers

**Environment Layer:**
- Purpose: Set up XDG directories, editor, locale, shell options, lazy-load NVM
- Location: `/config/environment.zsh`
- Contains: Export statements, zsh option configuration, NVM lazy-loading stub functions
- Depends on: None
- Used by: All downstream code

**Prompt Layer:**
- Purpose: Render interactive shell prompt with exit status indicator and git context
- Location: `/config/prompt.zsh`
- Contains: vcs_info configuration, exit code capture via precmd hooks, prompt formatting
- Depends on: environment (must know locale/colors)
- Used by: Interactive shell

**Alias Layer:**
- Purpose: Define command shortcuts for file ops, git, network, monitoring, tmux
- Location: `/config/aliases.zsh`
- Contains: ~40 aliases, platform detection for BSD vs GNU tools
- Depends on: None
- Used by: Interactive shell

**Functions Layer:**
- Purpose: Define utility functions for system operations and user conveniences
- Location: `/config/functions.zsh`
- Contains: mkcd, extract, whichip, weather, portfind, pan (macOS PDF viewer)
- Depends on: None
- Used by: Interactive shell

**Plugins Layer:**
- Purpose: Load external zsh plugins for completion and syntax highlighting
- Location: `/config/plugins.zsh`
- Contains: Plugin discovery from brew/apt/dnf paths, zsh-autosuggestions, zsh-syntax-highlighting
- Depends on: deps (plugins must exist), environment (needs PATH set)
- Used by: Interactive shell

**Monitoring Dashboard Layer:**
- Purpose: Orchestrate tmux-based system monitoring dashboard with multiple tools
- Location: `/config/monitor.zsh`
- Contains: Tool installation, tmux session orchestration, config file generation, sysmon command
- Depends on: environment (PATH)
- Used by: `sysmon` command

**Startup Splash Layer:**
- Purpose: Display system information and ASCII art on shell open
- Location: `/config/sysinfo.zsh`
- Contains: Platform detection, system data gathering (CPU, RAM, GPU, uptime), ASCII art randomization
- Depends on: environment (color codes)
- Used by: Interactive shell initialization

## Data Flow

**Shell Startup:**

1. `.zshrc` reads VERSION file
2. `.zshrc` defines `ZDOTDIR_CUSTOM` pointing to `~/.config/zsh`
3. For each module in order (deps → environment → prompt → aliases → functions → plugins → monitor → sysinfo):
   - Check file exists
   - Source file in current shell context
4. History configuration
5. Completion system setup (cached daily)
6. Key bindings
7. Source `~/.zshrc.local` if exists (user overrides)
8. sysinfo displays splash if interactive

**Command Execution (sysmon):**

1. User calls `sysmon`
2. Dispatcher checks subcommand (kill/status/help)
3. For default case (launch):
   - `_sysmon_ensure_deps()` runs `_sysmon_pkg_install` for each missing tool
   - Detect GPU presence via system_profiler (macOS) or lspci (Linux)
   - Force-write btop config to `~/.config/btop/btop.conf`
   - Force-write nvtop config to `~/.config/nvtop/interface.ini` (macOS only, hides N/A fields)
   - Create tmux session "sysmon" with btop in main pane
   - Conditional split: if GPU exists and nvtop installed, split right 40% for nvtop
   - Conditional subsplit: if macmon exists, split nvtop vertically for macmon
   - Configure tmux styling, enable mouse
   - Attach to session

**State Management:**

- Shell state: Variables exported to child processes, zsh options set
- Plugin/dependency state: Timestamp file `~/.cache/zsh/deps_checked` tracks last check (once per day)
- Completion state: `~/.cache/zsh/zcompdump*` cached daily
- History: Shared across sessions, deduplicated, in `~/.local/share/zsh/history`
- tmux session state: "sysmon" session persists on detach, can reattach with `sysmon`

## Key Abstractions

**Package Manager Abstraction:**
- Purpose: Support multiple package managers (brew, apt-get, dnf, pacman)
- Examples: `_sysmon_pkg_install` in `/config/monitor.zsh`, `_install_plugins` in `/config/deps.zsh`
- Pattern: Check which manager exists, call with appropriate flags

**Plugin Discovery:**
- Purpose: Find zsh plugins across multiple standard locations
- Examples: `_find_plugin` in `/config/plugins.zsh`
- Pattern: Search array of paths (brew share, /usr/share, /usr/local/share), return first match

**Platform Detection:**
- Purpose: Conditionally include macOS-specific or Linux-specific code
- Examples: Throughout codebase with `[[ "$OSTYPE" == darwin* ]]`
- Pattern: Check `$OSTYPE` at runtime, provide fallback for other platforms

**Lazy Function Loading:**
- Purpose: Defer expensive initialization until first use
- Examples: NVM in `/config/environment.zsh`
- Pattern: Define stub functions that call real source on first invocation, then call themselves

**Color Code Encapsulation:**
- Purpose: Keep color definitions in variables for consistency and easy theming
- Examples: `_D`, `_A`, `_N` in `/config/sysinfo.zsh` for dim, accent, reset
- Pattern: Define at function start, use throughout, unset on exit

## Entry Points

**Main Entry Point:**
- Location: `/.zshrc`
- Triggers: Shell initialization (every new terminal session)
- Responsibilities: Read version, set up directory paths, source all config modules in order, set up history/completion/bindings, source local overrides

**Installation Entry Point:**
- Location: `/install.sh`
- Triggers: Manual user execution for first-time setup
- Responsibilities: Check zsh installed, backup existing configs, create symlinks from `~/.zshrc` and `~/.config/zsh` to repo, create XDG data/cache dirs, optionally set default shell

**Deploy Entry Point:**
- Location: `/deploy.sh`
- Triggers: Manual user execution for releases
- Responsibilities: Check version file exists, check git state clean, push branch, create and push tag, extract changelog and create GitHub release

**Monitoring Dashboard Entry Point:**
- Location: `/config/monitor.zsh` function `sysmon()`
- Triggers: User calls `sysmon`, `sysmon kill`, `sysmon status`, or `sysmon help`
- Responsibilities: Parse subcommand, install missing tools if needed, launch/manage/report on tmux dashboard session

## Error Handling

**Strategy:** Fail fast with informative messages, provide recovery instructions, continue on non-critical errors

**Patterns:**
- Dependencies critical to shell startup: Check and error if missing (zsh check in install.sh)
- Optional dependencies (plugins, tools): Warn if missing, continue, attempt install on first use (deps.zsh, monitor.zsh)
- File operations: Use `-f` and `-d` tests before operations, use `mkdir -p` to prevent "not found" errors
- Command execution: Use `&>/dev/null` to suppress stderr/stdout, check `$?` or `command -v` to detect missing commands
- Function arguments: Validate input at function start with return 1, provide usage message

## Cross-Cutting Concerns

**Logging:**
- Console-based using echo/printf
- Color codes for status (green ✓ for success, red ✗ for error, cyan · for info, yellow → for warning)
- No file-based logging

**Validation:**
- Platform detection before platform-specific operations
- File existence checks before sourcing or reading
- Command availability checks before using (command -v)
- GPU detection before attempting GPU monitoring

**Authentication:**
- GPG_TTY set for gpg operations
- Git user name/email assumed to be pre-configured
- sudo used for package manager operations (apt-get, dnf, pacman)
- No login-based auth in shelly itself

**Performance:**
- Compinit completion system cached daily to avoid regeneration every startup
- Dependency check (deps_checked) done once per day
- NVM lazy-loaded to save ~300ms on startup
- Plugin discovery happens at source time, not on every command
- System info gathering is local-only (no network calls on startup)
