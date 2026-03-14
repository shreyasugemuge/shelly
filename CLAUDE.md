# Claude Context — Shelly

**Current version:** v4.2.1 (2026-03-14)

## What This Is

Shelly is a modular zsh configuration and development workspace by Shreyas Ugemuge. It lives in `~/.dotfiles/zsh` and gets symlinked into place by `install.sh`.

## Repo Layout

- `.zshrc` — entry point, sources all modules in `config/`
- `config/` — modular config files (environment, prompt, aliases, functions, plugins, deps, monitor, sysinfo)
- `install.sh` — setup script with backup, `--dry-run`, `--uninstall`
- `archive/` — legacy bash config preserved for reference, do not modify
- `to_delete/` — files staged for removal (not committed)

## Key Design Decisions

- **Color philosophy**: color conveys meaning, not decoration. Prompt face (yellow/red) signals exit status, git indicators (green/orange) signal repo state. Everything else stays muted/default.
- **Startup splash** (`sysinfo.zsh`): neofetch-style ASCII art + system stats. Labels are dim gray, values are default. No network calls on startup.
- **macOS-first, Linux-compatible**: `IS_MACOS` / `IS_LINUX` booleans set once in `.zshrc`, used everywhere. No scattered `$OSTYPE` checks.
- **XDG-compliant**: config lives under `~/.config/zsh/`, not directly in `$HOME`.
- **Performance**: NVM is lazy-loaded, compinit is cached daily, deps check runs once per day. PATH deduped via `typeset -U path`.
- **Plugin sourcing order**: zsh-syntax-highlighting MUST be sourced last in plugins.zsh. Guard comment in place — do not reorder.
- **No fzf**: completion uses native zsh `menu select` + `zsh-autosuggestions`. `devterm` uses numbered-list picker.
- **iTerm2 for sysmon and devterm**: both features use the `it2api` Python CLI bundled with iTerm2. Requires Python API enabled in iTerm2 preferences.
- **Force-written configs**: btop.conf and nvtop interface.ini are overwritten on every `sysmon` launch to prevent sticky-state bugs.
- **Startup caching**: sysinfo.zsh caches hardware info (until reboot), package count (1h), and git streak (5m) to ~/.cache/zsh/sysinfo_cache. brew --prefix computed once in .zshrc as _SHELLY_BREW_PREFIX and reused by deps/plugins.

## sysmon — System Monitor Dashboard

Launches an iTerm2 window with btop (left), nvtop (top-right), and macmon (bottom-right).

- Uses `it2api create-tab`, then `send-text btop` to launch btop in the initial pane; `split-pane --vertical` for nvtop, `split-pane` for macmon
- Split-pane failures are checked (null session ID guards) before sending commands
- Session ID tracked at `~/.cache/zsh/sysmon.session_id`; `sysmon` re-focuses if open, re-launches if closed
- `sysmon kill` finds the window via `show-hierarchy` and closes it via AppleScript
- btop.conf and nvtop interface.ini force-written on every launch (see design decision above)
- macOS-only; nvtop N/A fields on Apple Silicon hidden via force-written config
- Inactive pane dimming disabled on launch (saved/restored on kill via `DimInactiveSplitPanes` defaults)

### Subcommands
`sysmon` — launch or focus | `sysmon kill` — close window | `sysmon status` — tool versions + window state | `sysmon help`

## devterm — Dynamic Dev Workspace

Launches an iTerm2 window with one column per project (Claude Code top 80% + terminal bottom 20%).

- Numbered-list picker; 1-3 projects from `$DEVTMUX_DIR` (default `~/code`); append `y` for yolo mode; worktrees detected alongside normal repos
- **Three-phase build**: (1) create all splits and navigate panes to project dirs, (2) resize horizontal splits to 80/20 via Python API tree walk (`_dev_resize_layout`), (3) clear scrollback via `inject ClearScrollback` and launch Claude
- **Pane titles**: top panes titled `claude :: project` (or `⚡ claude :: project` for yolo), bottom panes titled `terminal :: project`; set via `inject` (invisible)
- **Title locking**: Claude panes use `set-profile-property allow_title_setting false` so Claude Code cannot override the pane title
- **Stale session cleanup**: `_dev_build_session` always closes any tracked window before creating a new one
- Session ID tracked at `~/.cache/zsh/devterm.session_id`
- `devtmux` still works as a deprecation shim redirecting to `devterm`

### Subcommands
`devterm` — pick and launch | `devterm kill` — close window | `devterm status` | `devterm help`

## Versioning & Releases

Follows semver. Update `VERSION`, `CHANGELOG.md`, commit `chore: bump version`, tag and push.

## Commit Style

Conventional-ish prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `style:`

## Gotchas

- Never commit secrets, credentials, or machine-specific paths
- `ls` alias in `aliases.zsh` has BSD/GNU detection — don't simplify it
- `plugins.zsh` must source syntax-highlighting LAST — guard comment in place, do not reorder
- Platform checks use `$IS_MACOS` / `$IS_LINUX` (set in `.zshrc`), not `$OSTYPE`
- Shellcheck zero-warning baseline — no new warnings without inline suppressions
- `portfind` validates port range (1-65535), `mkcd` validates non-empty args
- `~/.zshrc.local` is for machine-specific overrides — not tracked in git
- btop has NO `--conf` CLI flag — it always reads `~/.config/btop/btop.conf`
- btop and nvtop configs ARE force-written by monitor.zsh on every `sysmon` launch — intentional
- `sysmon` and `devterm` check `$TERM_PROGRAM == "iTerm.app"` — in any other terminal they print a "non-iTerm mode" message and exit cleanly
- `it2api` requires the Python `iterm2` module and the iTerm2 Python API to be enabled
- In zsh, `local var` (without `=""`) inside a loop prints `var=value` to stdout on re-entry — always use `local var=""` when declaring variables in loops
- sysinfo cache at ~/.cache/zsh/sysinfo_cache — delete it to force a full refresh on next shell open
- _SHELLY_BREW_PREFIX is set in .zshrc before modules and unset after — modules must not depend on it persisting
