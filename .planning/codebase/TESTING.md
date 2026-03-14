# Testing

## Overview

Shelly has **no automated testing framework**. Testing is entirely manual through shell reloads and functional verification. This is typical for shell configuration projects.

## Manual Testing Approach

### Shell Reload
After any config change:
```bash
exec zsh
```
Verifies: no syntax errors, startup splash renders, prompt works, aliases resolve.

### Installation Testing
```bash
./install.sh --dry-run    # Preview what would be changed
./install.sh              # Run installation
./install.sh --uninstall  # Reverse installation
```

### sysmon Dashboard Testing
```bash
sysmon status   # Check tool availability
sysmon          # Launch dashboard, verify layout
sysmon kill     # Clean teardown
```

### Function Testing
Functions in `config/functions.zsh` are tested by invoking them directly:
- `mkcd testdir` — creates and enters directory
- `extract file.tar.gz` — extracts archive
- `weather` — fetches weather (requires network)

## Built-in Preflight Checks

Several scripts include their own validation:

### install.sh
- Checks for existing `.zshrc` before overwriting
- Creates backups before symlinking
- `--dry-run` mode shows actions without executing

### deps.zsh
- Runs once per day (cached via timestamp file)
- Checks for required tools (brew, git, etc.)
- Reports missing dependencies

### monitor.zsh
- `sysmon status` checks if btop, nvtop, macmon are installed
- Auto-installs missing tools via package manager
- Platform detection before launching macOS-only tools

## Lessons Learned (from CLAUDE.md retrospectives)

1. **btop --conf flag does not exist** — Always verify CLI flags with `--help` before using them
2. **Config file writes create sticky state** — Force-write approach adopted to prevent stale configs surviving git reverts
3. **sudo in tmux panes fails silently** — Tools requiring sudo need pre-auth or visible fallback
4. **nvtop ~80% broken on Apple Silicon** — Don't assume Linux tools work fully on macOS
5. **Git lock files in sandboxed environments** — May need GitHub API workaround
6. **Don't over-iterate on replacements** — When something works "well enough", improve incrementally

## Testing Gaps

- No unit tests for shell functions
- No integration tests for install/uninstall cycle
- No CI pipeline
- No linting (e.g., shellcheck) configured
- Plugin compatibility untested across zsh versions
