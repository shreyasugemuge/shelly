# Claude Context — Shelly

**Current version:** v4.8.1 (2026-03-28)

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
- **Force-written configs**: btop.conf is overwritten on every `sysmon` launch to prevent sticky-state bugs. mactop needs no config file.
- **Startup caching**: sysinfo.zsh caches hardware info (until reboot), package count (1h), and git streak (5m) to ~/.cache/zsh/sysinfo_cache. brew --prefix computed once in .zshrc as _SHELLY_BREW_PREFIX and reused by deps/plugins.

## sysmon — System Monitor Dashboard

Launches an iTerm2 tab with btop (left) and mactop (right).

- Uses `it2api create-tab --window WINDOW_ID` to open a tab in the current window, then `send-text btop` to launch btop in the initial pane; `split-pane --vertical` for mactop
- Split-pane failures are checked (null session ID guards) before sending commands
- Session ID tracked at `~/.cache/zsh/sysmon.session_id`; `sysmon` re-focuses if open, re-launches if closed
- `sysmon kill` finds the tab via `show-hierarchy` and closes it via AppleScript
- btop.conf force-written on every launch (see design decision above); mactop auto-detects Apple Silicon
- Inactive pane dimming disabled on launch (saved/restored on kill via `DimInactiveSplitPanes` defaults)
- `sysmon-old` preserves the legacy nvtop+macmon layout with its own state file

### Subcommands
`sysmon` — launch or focus | `sysmon kill` — close tab | `sysmon status` — tool versions + tab state | `sysmon help` | `sysmon-old` — legacy layout

## devterm — Dynamic Dev Workspace

Launches an iTerm2 tab with one column per project (Claude Code top 80% + terminal bottom 20%).

- Numbered-list picker; 1-3 projects from `$DEVTMUX_DIR` (default `~/code`); append `y` for yolo mode; worktrees detected alongside normal repos
- **Three-phase build**: (1) create all splits and navigate panes to project dirs, (2) resize horizontal splits to 80/20 via Python API tree walk (`_dev_resize_layout`), (3) clear scrollback via `inject ClearScrollback` and launch Claude
- **Pane titles**: top panes titled `claude :: project` (or `⚡ claude :: project` for yolo), bottom panes titled `terminal :: project`; set via `inject` (invisible)
- **Title locking**: Claude panes use `set-profile-property allow_title_setting false` so Claude Code cannot override the pane title
- **Stale session cleanup**: `_dev_build_session` always closes any tracked tab before creating a new one
- Session ID tracked at `~/.cache/zsh/devterm.session_id`
- `devtmux` still works as a deprecation shim redirecting to `devterm`

### Subcommands
`devterm` — pick and launch | `devterm kill` — close tab | `devterm status` | `devterm config` — show/change code directory | `devterm config reset` — reset to default | `devterm help`

### Split Mode (`devterm -s`)

Opens a single project with 1-8 equal-sized Claude panes in an optimal grid layout. Every pane runs `claude --dangerously-skip-permissions`.

- **Grid algorithm**: 1→full, 2→[2], 3→[3], 4→[2×2], 5→[2+2+1], 6→[3×3], 7→[3+3+1], 8→[4×4]
- **Build strategy**: rows first (horizontal splits), then columns within each row (vertical splits), then Python API equalize
- **Separate state**: tracked at `~/.cache/zsh/devterm-split.session_id` — regular devterm and split mode can coexist
- **Pane titles**: `⚡ N :: project` (numbered, title-locked)

#### Split Subcommands
`devterm -s` — pick project and launch | `devterm -s -c` — use current directory (skip picker) | `devterm -s kill` — close split tab | `devterm -s status` | `devterm -s help`

## Versioning & Releases

**Always use `shelly release <major|minor|patch>`.** Do not manually edit VERSION, do not manually update CHANGELOG links, do not manually tag or push. The command handles everything: VERSION bump, CHANGELOG sectioning, commit, tag, and push.

Before running `shelly release`, ensure:
1. All feature/fix commits are already on master
2. The `## [Unreleased]` section in CHANGELOG.md has entries describing the changes
3. Working tree is clean

The release commit message is always `chore: release v<version>` — feature commits use their own prefixes (`feat:`, `fix:`, etc.) and should already be committed before releasing.

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
- btop config IS force-written by monitor.zsh on every `sysmon` launch — intentional
- `sysmon` and `devterm` check `$TERM_PROGRAM == "iTerm.app"` — in any other terminal they print a "non-iTerm mode" message and exit cleanly
- `it2api` requires the Python `iterm2` module and the iTerm2 Python API to be enabled
- In zsh, `local var` (without `=""`) inside a loop prints `var=value` to stdout on re-entry — always use `local var=""` when declaring variables in loops
- sysinfo cache at ~/.cache/zsh/sysinfo_cache — delete it to force a full refresh on next shell open
- _SHELLY_BREW_PREFIX is set in .zshrc before modules and unset after — modules must not depend on it persisting

<!-- GSD:profile-start -->
## Developer Profile

> Generated by GSD from questionnaire. Run `/gsd:profile-user --refresh` to update.

| Dimension | Rating | Confidence |
|-----------|--------|------------|
| Communication | mixed | LOW |
| Decisions | deliberate-informed | MEDIUM |
| Explanations | detailed | MEDIUM |
| Debugging | diagnostic | MEDIUM |
| UX Philosophy | design-conscious | MEDIUM |
| Vendor Choices | thorough-evaluator | MEDIUM |
| Frustrations | instruction-adherence | MEDIUM |
| Learning | guided | MEDIUM |

**Directives:**
- **Communication:** Adapt response detail to match the complexity of each request. Brief for simple tasks, detailed for complex ones.
- **Decisions:** Present options in a structured comparison table with pros/cons. Let the developer make the final call.
- **Explanations:** Explain the approach, key trade-offs, and code structure alongside the implementation. Use headers to organize.
- **Debugging:** Diagnose the root cause before presenting the fix. Explain what went wrong and why the fix addresses it.
- **UX Philosophy:** Invest in UX quality: thoughtful spacing, smooth transitions, responsive layouts. Treat design as a first-class concern.
- **Vendor Choices:** Compare alternatives with specific metrics (bundle size, GitHub stars, maintenance activity). Support informed decisions.
- **Frustrations:** Follow instructions precisely. Re-read constraints before responding. If requirements conflict, flag the conflict rather than silently choosing. Never break working code while fixing something else -- verify existing functionality is preserved.
- **Learning:** Explain concepts in context of the developer's codebase. Use their actual code as examples when teaching.
<!-- GSD:profile-end -->
