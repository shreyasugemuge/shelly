# Coding Conventions

**Analysis Date:** 2026-03-14

## Naming Patterns

**Files:**
- Lowercase with `.zsh` or `.sh` extension: `environment.zsh`, `deploy.sh`
- Private helper functions prefixed with underscore: `_sysmon_launch`, `_plugin_installed`, `_should_check_deps`
- Public functions without prefix: `sysmon`, `mkcd`, `extract`, `weather`
- Temporary/internal variables prefixed with underscore: `_zsh_deps`, `_deps_stamp`, `_plugin_dirs`

**Functions:**
- Descriptive, action-oriented names: `_sysmon_launch`, `_plugin_installed`, `check_zsh`, `backup_existing`
- Private helper functions prefixed with underscore to indicate internal scope
- Entry point functions without prefix: `sysmon`, `mkcd`, `extract`, `whichip`, `pan`, `weather`, `portfind`

**Variables:**
- User-visible exports: uppercase with underscores: `ZDOTDIR_CUSTOM`, `EDITOR`, `HISTFILE`, `NVM_DIR`
- Internal/local variables: prefixed with `_`: `_zsh_deps`, `_deps_stamp`, `_plugin_dirs`, `_nvm_script`, `_prompt_face`
- Arrays use Zsh array syntax: `_plugin_dirs=()`, `_f_stats=()`
- Color codes use mnemonic prefixes: `_D='\033[0;90m'` (dim), `_A='\033[0;33m'` (accent), `_N='\033[0m'` (null/reset)

**Types/Constants:**
- Configuration constants named descriptively: `_SYSMON_SESSION`, `REPO_DIR`, `BACKUP_DIR`
- Status/flag variables: `DRY_RUN=false`, `UNINSTALL=false`, `installed_something=false`

## Code Style

**Formatting:**
- No automated formatter — conventions are manual
- Indentation: 4 spaces (Bash/Zsh files)
- Line length: no hard limit, but keep under 120 characters where reasonable
- Each config module is self-contained (~50-300 lines, focused on one purpose)

**Linting:**
- No linter configured (ShellCheck/shfmt not used)
- Manual review via code comments and CLAUDE.md retrospectives
- Error handling is explicit: every function that can fail includes `return 1` on error

**Line Endings:**
- Unix (`\n` only, no `\r\n`)
- Bash shebang: `#!/bin/bash` with `set -euo pipefail` for deploy/install scripts
- Zsh shebang: `#!/bin/zsh` for config modules

## Import Organization

**Order in `.zshrc` (`.zshrc` files):**
1. Version setup (read from VERSION file)
2. Set `ZDOTDIR_CUSTOM` directory
3. Source modular configs in dependency order:
   - `deps.zsh` — must come first (installs missing plugins)
   - `environment.zsh` — exports, options, paths
   - `prompt.zsh` — prompt setup (depends on colors)
   - `aliases.zsh` — command shortcuts
   - `functions.zsh` — utility functions
   - `plugins.zsh` — plugin loading (must come after functions)
   - `monitor.zsh` — sysmon function
   - `sysinfo.zsh` — startup splash (must come last)
4. History configuration
5. Completion setup
6. Key bindings
7. Local overrides sourcing (`~/.zshrc.local`)

See `.zshrc` (lines 18-32) for exact order in `.zshrc`.

**Within modules:**
- All imports use absolute paths via `ZDOTDIR_CUSTOM` or `XDG_*` directories
- No relative path imports
- Functions always defined before use (no forward declarations)

**Path Aliases:**
- None used — all paths are explicit and XDG-compliant
- `ZDOTDIR_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"` provides the config directory

## Error Handling

**Patterns:**
- Functions that may fail explicitly `return 1` on error and print error message to stdout
- Error messages format: `function_name: error message` (e.g., `extract: unknown format '$1'`)
- Scripts use `set -euo pipefail` (exit on error, undefined vars error, pipe failures error)
- Exit codes follow convention: 0 = success, 1 = error

**Examples:**
```bash
# Function with error check (config/functions.zsh)
function mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Script with error handling (install.sh)
check_zsh() {
    if ! command -v zsh &>/dev/null; then
        err "zsh is not installed"
        echo ""
        echo "  Install it with:"
        # ... help text ...
        exit 1
    fi
}
```

**Silent Success:**
- When all dependencies are already installed, `deps.zsh` runs completely silently (no stdout)
- Tools only print to stdout on state changes or errors
- Startup info is optional and can be disabled by sourcing `~/.zshrc.local`

## Logging

**Framework:** None — uses plain `echo` / `echo -e` for color output

**Patterns:**
- Logging helper functions in scripts: `ok()`, `warn()`, `err()`, `info()`
- Color codes: green `✓`, yellow `→`, red `✗`, cyan `·`
- Format: `echo -e "  ${GREEN}✓${NC} message"`
- Example from `install.sh`:
```bash
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}→${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${CYAN}·${NC} $1"; }

ok "zsh found: $(zsh --version | head -1)"
```

**When to Log:**
- State changes: tool installed, config written, session started/stopped
- Errors: missing dependencies, failed checks, uncommitted changes
- Progress: during multi-step operations (install, deploy, sysmon launch)
- Debug: use stderr redirect (not used currently)

## Comments

**When to Comment:**
- Non-obvious conditionals: explain WHY a check is needed
- Complex shell operations: explain intent (e.g., parameter expansion, subshells)
- Gotchas and workarounds: documented via inline comments and CLAUDE.md retrospectives
- Section headers: `# ── Section Name ──` format for visual separation

**JSDoc/TSDoc:**
- Not used (shell scripts don't support standardized doc comments)
- Function documentation via inline comments above function definition

**Example from `config/monitor.zsh`:**
```zsh
# ── Force-write btop config: CPU + memory + network ──
# Removes disks and process table so CPU core graphs get more space.
# Written fresh on every launch.
local btop_conf="${XDG_CONFIG_HOME:-$HOME/.config}/btop/btop.conf"
mkdir -p "${btop_conf:h}"
cat > "$btop_conf" << 'BTOPEOF'
...
BTOPEOF
```

## Function Design

**Size:**
- Most functions 5–30 lines
- Complex functions (like `_sysmon_launch`, `_install_plugins`) up to 60 lines
- Single responsibility: each function does one thing well

**Parameters:**
- Single parameter or no parameters preferred
- Use `"$1"`, `"$2"` for explicit params (not "$@" unless spreading)
- Parameter validation at function start:
```zsh
function pan() {
    if [[ -z "$1" ]]; then
        echo "Usage: pan <command>"
        return 1
    fi
    # ... function body ...
}
```

**Return Values:**
- Exit code: 0 = success, 1 = error
- Stdout for data/output (e.g., `_find_plugin` echoes the path)
- No explicit `return` needed on success (implicit 0)
- Explicit `return 1` for errors

**Example (config/plugins.zsh):**
```zsh
_find_plugin() {
    local plugin="$1"
    for _dir in "${_plugin_dirs[@]}"; do
        if [[ -f "$_dir/$plugin/$plugin.zsh" ]]; then
            echo "$_dir/$plugin/$plugin.zsh"    # Output the path
            return 0                             # Explicit success
        fi
    done
    return 1                                     # Explicit failure
}
```

## Module Design

**Exports:**
- Each module exports only what's needed (environment vars, functions, aliases)
- Example from `config/environment.zsh`: exports `XDG_*`, `EDITOR`, `LANG`, `NVM_DIR`
- Private functions prefixed with `_` to indicate internal scope

**No Barrel Files:**
- No centralized re-export files
- Each module is sourced directly in order in `.zshrc`

**Unset Pattern:**
- After setup, temporary variables are unset to avoid polluting the shell namespace
- Example from `config/environment.zsh`:
```zsh
_lazy_load_nvm() {
    # ... function body ...
}
for _cmd in nvm node npm npx; do
    eval "${_cmd}() { _lazy_load_nvm; ${_cmd} \"\$@\" }"
done
unset _cmd _nvm_script    # Clean up after setup
```

## Platform Handling

**macOS/Linux Guard Pattern:**
```zsh
if [[ "$OSTYPE" == darwin* ]]; then
    # macOS-specific code
else
    # Linux fallback
fi
```

- Always provide a fallback for Linux (used in functions like `pan`, `whichip`, `extract`)
- For tools that only work on macOS (like `macmon`), print a helpful message on Linux

## Performance

**Optimization Principles:**
- Lazy-load expensive operations: NVM sourcing deferred until first use (saves ~300ms)
- Cache completion dump: regenerated once per day instead of every shell start
- Dependency check runs once per day: timestamp stored in `~/.cache/zsh/deps_checked`
- Startup splash (sysinfo) runs only in interactive shells: `[[ ! -o interactive ]] && return 0`

## Zsh-Specific Idioms

**Array Syntax:**
```zsh
_plugin_dirs=()                      # Declare empty array
_plugin_dirs+=("$_brew_share")       # Append to array
for _dir in "${_plugin_dirs[@]}"; do # Iterate over array
    # ... body ...
done
```

**Parameter Expansion:**
```zsh
${1:-default}           # Default value if unset
${var:h}                # Directory (head) of path
${var:t}                # Tail (filename) of path
${#array[@]}            # Array length
${array[index]}         # Array element access
```

**Arithmetic:**
```zsh
(( ${#missing[@]} == 0 ))  # Arithmetic test (true if array empty)
(( _f_days > 0 ))          # Numeric comparison
```

**Zstyle (Completion):**
```zsh
zstyle ':completion:*' menu select              # Enable menu selection
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case-insensitive
```

---

*Convention analysis: 2026-03-14*
