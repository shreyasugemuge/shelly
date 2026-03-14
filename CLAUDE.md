# Claude Context — Shelly

**Current version:** v4.0.1 (2026-03-14)

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

## sysmon — System Monitor Dashboard

Launches an iTerm2 window with btop (left), nvtop (top-right), and macmon (bottom-right).

- Uses `it2api create-tab --command btop`, then `split-pane --vertical` for nvtop, `split-pane` for macmon
- Session ID tracked at `~/.cache/zsh/sysmon.session_id`; `sysmon` re-focuses if open, re-launches if closed
- `sysmon kill` finds the window via `show-hierarchy` and closes it via AppleScript
- btop.conf and nvtop interface.ini force-written on every launch (see design decision above)
- macOS-only; nvtop N/A fields on Apple Silicon hidden via force-written config

### Subcommands
`sysmon` — launch or focus | `sysmon kill` — close window | `sysmon status` — tool versions + window state | `sysmon help`

## devterm — Dynamic Dev Workspace

Launches an iTerm2 window with one column per project (Claude Code top + figlet terminal bottom).

- Numbered-list picker; 1-3 projects from `$DEVTMUX_DIR` (default `~/code`); append `y` for yolo mode
- Uses `it2api create-tab`, then `split-pane --vertical` for additional columns, `split-pane` for terminal rows
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
