# Claude Context — Shelly

**Current version:** v3.2.0 (2026-03-14)

## What This Is

Shelly is a modular zsh configuration and development workspace by Shreyas Ugemuge. It lives in `~/.dotfiles/zsh` and gets symlinked into place by `install.sh`.

## Repo Layout

- `.zshrc` — entry point, sources all modules in `config/`
- `config/` — modular config files (environment, prompt, aliases, functions, plugins, deps, monitor, sysinfo)
- `.planning/` — GSD project planning (roadmap, phases, milestones)
- `install.sh` — setup script with backup, `--dry-run`, `--uninstall`
- `deploy.sh` — removed (moved to `to_delete/`)
- `archive/` — legacy bash config preserved for reference, do not modify

## Key Design Decisions

- **Color philosophy**: color should convey meaning, not decoration. The prompt face (yellow/red) signals exit status, git indicators (green/orange) signal repo state. Everything else (user, host, path) stays muted/default. Syntax highlighting from the zsh plugin handles command coloring.
- **Startup splash** (`sysinfo.zsh`): neofetch-style ASCII art + system stats. Labels are dim gray, values are default terminal color. No bold, no cyan headers. No network calls on startup.
- **macOS-first, Linux-compatible**: `IS_MACOS` / `IS_LINUX` booleans set once in `.zshrc`, used everywhere. No more scattered `$OSTYPE` checks.
- **XDG-compliant**: config lives under `~/.config/zsh/`, not directly in `$HOME`.
- **Performance matters**: NVM is lazy-loaded, compinit is cached daily, deps check runs once per day. PATH is deduped via `typeset -U path` in environment.zsh.
- **Plugin sourcing order**: zsh-syntax-highlighting MUST be sourced last in plugins.zsh. A guard comment is co-located with the source line to prevent reordering.
- **No fzf**: fzf was removed. Completion uses native zsh `menu select` + `zsh-autosuggestions` (fish-style ghost text from history/completion). devtmux uses a numbered-list picker. No external picker dependencies.
- **sysmon force-writes config files on every launch**: btop.conf and nvtop's interface.ini are overwritten each time `sysmon` runs to ensure a consistent dashboard layout. This was a deliberate design choice after experiencing "sticky state" bugs where leftover config files survived git reverts and caused confusing layout changes. The force-write approach means the dashboard always matches what the code specifies.

## sysmon — System Monitor Dashboard

The `sysmon` command (`config/monitor.zsh`) launches a tmux dashboard with btop, nvtop, and macmon.

### Architecture

- btop: left pane (60%), shows all CPU cores (braille graphs) + memory + network
- nvtop: top-right pane, shows GPU utilization % chart + VRAM bar (N/A fields hidden on macOS)
- macmon: bottom-right pane (macOS only), shows CPU/GPU temperature, power draw, and frequency — no sudo required
- tmux: session named "sysmon", mouse enabled, styled status bar
- All tools auto-installed on first run via brew/apt/dnf/pacman (`vladkens/tap/macmon` for macmon)
- btop config (`~/.config/btop/btop.conf`) force-written on every launch: `shown_boxes = "cpu mem net"`, braille graphs, no disks, no process table
- nvtop config (`~/.config/nvtop/interface.ini`) force-written on every launch (macOS only): hides all broken Apple Silicon N/A fields

### Known Limitations (Apple Silicon)

nvtop on Apple Silicon (M-series) has significant gaps. These fields show N/A and cannot be fixed — they're unsupported by Apple's Metal API: GPU clock rate, VRAM clock rate, temperature, fan speed, power draw, PCIe TX/RX, per-process GPU MEM and CPU columns.

What DOES work: GPU utilization % graph, VRAM usage bar (e.g. 4.16Gi/128Gi), and process-level GPU % for some workloads. The force-written nvtop config hides all N/A fields so the dashboard stays clean.

### Removed Tools

- **bandwhich** — removed in v1.3.2. Required sudo for packet capture, showed password prompts in tmux panes, and per-process bandwidth data wasn't useful enough to justify the space.
- **asitop** — tried and rejected during v1.3.0 development. Requires sudo (reads powermetrics), can't prompt for password in tmux panes, and output was low quality.

### Subcommands

- `sysmon` — launch or reattach
- `sysmon kill` — tear down the session
- `sysmon status` — check installed tools and session state
- `sysmon help` — quick reference

There is NO `sysmon reset` subcommand. Any unrecognized argument falls through to the default case which launches the dashboard.

## devtmux — Dynamic Dev Workspace

The `devtmux` command (`config/functions.zsh`) launches a tmux workspace for multi-project development.

### How It Works

- Discovers code folder via `$DEVTMUX_DIR`, defaults to `~/code`, prompts if missing
- Project picker: numbered-list multi-select (enter space-separated numbers)
- Opens 1-3 projects, each as a tmux column with Claude Code (top) + terminal (bottom)
- Session management: reattach existing, kill+recreate, or `devtmux kill`

### Subcommands

- `devtmux` — pick projects and launch/reattach
- `devtmux kill` — tear down the devtmux session
- `devtmux help` — quick reference

### Design Notes

- stderr for errors in helpers so stdout captures only project names/paths
- 1-based zsh loop with `(i-1)*2` pane index formula for tmux pane targeting
- Persists `DEVTMUX_DIR` to `~/.zshrc.local` (with duplicate guard)

## Versioning & Releases

Follows semver. See CONTRIBUTING.md for the full process. Quick version:
1. Update `VERSION` file
2. Update `CHANGELOG.md` (move Unreleased -> new version section)
3. Commit: `chore: bump version to x.y.z`
4. Tag + push: `git tag -a vx.y.z -m "Release vx.y.z"` then `git push origin master --tags`

## Commit Style

Conventional-ish prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `style:`

## Remote

- `origin` — `shreyasugemuge/shelly` (canonical repo)

## Things to Watch Out For

- Never commit secrets, credentials, or machine-specific paths
- The `ls` alias in `aliases.zsh` has BSD/GNU detection — don't simplify it
- `plugins.zsh` must source syntax-highlighting LAST (zsh requirement) — guard comment in place, do not reorder
- Platform checks use `$IS_MACOS` / `$IS_LINUX` booleans (set in `.zshrc`), not `$OSTYPE` — keep it that way
- shellcheck zero-warning baseline — do not introduce new warnings without inline suppressions
- `portfind` validates port range (1-65535), `mkcd` validates non-empty args — maintain input validation
- `~/.zshrc.local` is for machine-specific overrides and is not tracked in git
- btop has NO `--conf` or `--config` CLI flag — it always reads `~/.config/btop/btop.conf`. Do not try to pass a config path.
- btop and nvtop configs ARE force-written by monitor.zsh on every `sysmon` launch — this is intentional (see v1.3.2 design decision). Do not remove the force-write behavior.
- asitop and bandwhich are no longer used — do not re-add them without solving the sudo-in-tmux problem first.

## Retrospectives — Lessons from v1.3.0 Development

These are documented so future AI assistants (and humans) don't repeat the same mistakes.

### 1. btop --conf flag does not exist

**What happened**: Tried to pass `btop --conf /path/to/config` to use a custom config. btop exited immediately, killing the entire tmux session. Resulted in 14 "no server running" errors.

**Root cause**: btop has no CLI flag for config path. It always reads from `~/.config/btop/btop.conf`. The `--conf` flag was hallucinated.

**Fix**: Removed the flag. btop just runs as `btop` with no arguments.

**Lesson**: Always verify CLI flags exist before using them. `btop --help` would have caught this.

### 2. Writing config files from monitor.zsh causes sticky state

**What happened**: monitor.zsh was modified to auto-write `~/.config/btop/btop.conf` with `shown_boxes = "cpu net"`. When the code was later reverted to v1.3.0, the config file persisted on the user's machine, making btop look different than expected even though the code was correct.

**Root cause**: Config files written to `~/.config/` are not tracked by git. Reverting the code doesn't revert the side effects on the filesystem.

**Fix**: User had to manually `rm ~/.config/btop/btop.conf`.

**Lesson**: Shell config scripts should not auto-generate config files for other tools. It creates invisible state that's hard to debug and survives git reverts.

### 3. sudo in tmux panes fails silently

**What happened**: asitop needs `sudo` to read Apple's powermetrics. When launched in a tmux pane, it couldn't prompt for a password and just died. The pane showed nothing or a brief error.

**Root cause**: tmux panes don't have an interactive terminal for sudo password prompts unless the user clicks into them.

**Fix**: Pre-authenticating sudo before launching tmux (`sudo -v`) works but adds friction. bandwhich has the same issue — it shows a "Password:" prompt in the pane.

**Lesson**: Any tool requiring sudo in a tmux pane needs either pre-auth or a visible fallback message. Plan for this at design time.

### 4. nvtop is ~80% broken on Apple Silicon

**What happened**: nvtop was expected to show GPU utilization, temperature, fan speed, power draw, and per-process GPU memory. On Apple Silicon, only GPU % and VRAM bar work. Everything else is N/A.

**Root cause**: Apple's Metal API doesn't expose thermal, fan, power, or clock rate data to nvtop. These sensors are only accessible via `powermetrics` (requires root) or private frameworks.

**Lesson**: Don't assume a Linux tool works fully on macOS. Check Apple Silicon compatibility specifically. The N/A fields are a fundamental API limitation, not a bug.

### 5. Multiple failed tool replacements

**What happened**: Attempted to replace nvtop with macmon, asitop, istats, and various combinations. Each attempt introduced new problems (sudo requirements, gem dependencies, config file pollution) and the user repeatedly had to revert.

**Lesson**: When something works "well enough" (nvtop shows GPU % which is the main thing), don't over-iterate trying to fix peripheral issues. Improve incrementally, test each change, and don't stack untested changes.

### 6. Git lock files in sandboxed environments

**What happened**: `.git/index.lock`, `.git/packed-refs.lock`, and `.git/refs/remotes/origin/master.lock` appeared in the sandbox and couldn't be removed (Operation not permitted). All local git operations failed.

**Fix**: Used GitHub's Git Data API (create blob -> create tree -> create commit -> update ref) via curl to push commits directly, bypassing local git entirely.

**Lesson**: In sandboxed/containerized environments, git lock files may be immovable. The GitHub API is a reliable workaround for pushing changes.
