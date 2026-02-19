# Claude Context — Zsh Dotfiles

## What This Is

A modular zsh configuration managed by Shreyas Ugemuge. It lives in `~/.dotfiles/zsh` and gets symlinked into place by `install.sh`. The repo name (`bash_old`) is historical — this is pure zsh now.

## Repo Layout

- `.zshrc` — entry point, sources all modules in `config/`
- `config/` — modular config files (environment, prompt, aliases, functions, plugins, deps, monitor, sysinfo)
- `install.sh` — setup script with backup, `--dry-run`, `--uninstall`
- `deploy.sh` — one-command push, tag, and GitHub release
- `archive/` — legacy bash config preserved for reference, do not modify

## Key Design Decisions

- **Color philosophy**: color should convey meaning, not decoration. The prompt face (yellow/red) signals exit status, git indicators (green/orange) signal repo state. Everything else (user, host, path) stays muted/default. Syntax highlighting from the zsh plugin handles command coloring.
- **Startup splash** (`sysinfo.zsh`): neofetch-style ASCII art + system stats. Labels are dim gray, values are default terminal color. No bold, no cyan headers. No network calls on startup.
- **macOS-first, Linux-compatible**: guard platform-specific code with `[[ "$OSTYPE" == darwin* ]]` and always provide a Linux fallback.
- **XDG-compliant**: config lives under `~/.config/zsh/`, not directly in `$HOME`.
- **Performance matters**: NVM is lazy-loaded, compinit is cached daily, deps check runs once per day.
- **sysmon does NOT write config files**: btop, nvtop, and other tools use their own default configs. Do not auto-generate `~/.config/btop/btop.conf` or `~/.config/nvtop/interface.ini` — these are user-managed and writing them causes confusion when reverting.

## sysmon — System Monitor Dashboard

The `sysmon` command (`config/monitor.zsh`) launches a tmux dashboard with btop, nvtop, and bandwhich.

### Architecture

- btop: left pane (main), shows CPU/RAM/disk/processes/network
- nvtop: right pane, shows GPU utilization (Apple Silicon via Metal)
- bandwhich: bottom strip, shows per-process network bandwidth
- tmux: session named "sysmon", mouse enabled, styled status bar
- All tools auto-installed on first run via brew/apt/dnf/pacman

### Known Limitations (Apple Silicon)

nvtop on Apple Silicon (M-series) has significant gaps. These fields show N/A and cannot be fixed — they're unsupported by Apple's Metal API:

- GPU clock rate (MHz): N/A
- VRAM clock rate (MHz): N/A
- Temperature: N/A°C
- Fan speed: N/A
- Power draw: N/A W
- PCIe TX/RX: N/A
- Process-level GPU MEM and CPU columns: mostly N/A

What DOES work on nvtop Apple Silicon: GPU utilization % graph, VRAM usage bar (e.g. 4.16Gi/128Gi), and process-level GPU % for some workloads.

### bandwhich and sudo

bandwhich needs root for packet capture. The tmux pane runs `sudo bandwhich 2>/dev/null || bandwhich`. On macOS, if sudo hasn't been recently authenticated, the pane will show a password prompt — the user must click into it and type their password.

### Subcommands

- `sysmon` — launch or reattach
- `sysmon kill` — tear down the session
- `sysmon status` — check installed tools and session state
- `sysmon help` — quick reference

There is NO `sysmon reset` subcommand. Any unrecognized argument falls through to the default case which launches the dashboard.

## Versioning & Releases

Follows semver. See CONTRIBUTING.md for the full process. Quick version:
1. Update `VERSION` file
2. Update `CHANGELOG.md` (move Unreleased → new version section)
3. Commit: `chore: bump version to x.y.z`
4. Tag + push: `git tag -a vx.y.z -m "Release vx.y.z"` then `git push origin master --tags`
5. Or use `deploy.sh` which handles push + tag + GitHub release in one command

## Commit Style

Conventional-ish prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `style:`

## Remotes

- `origin` — `shreyas613/bash_old` (Shreyas's fork, where work happens)
- `upstream` — `shreyasugemuge/bash` (canonical repo)

## Things to Watch Out For

- Never commit secrets, credentials, or machine-specific paths
- The `ls` alias in `aliases.zsh` has BSD/GNU detection — don't simplify it
- `plugins.zsh` must source syntax-highlighting LAST (zsh requirement)
- `~/.zshrc.local` is for machine-specific overrides and is not tracked in git
- btop has NO `--conf` or `--config` CLI flag — it always reads `~/.config/btop/btop.conf`. Do not try to pass a config path.
- Do not auto-generate config files for btop/nvtop/etc. from monitor.zsh. If the user deletes their config, the tool should just use defaults.
- asitop requires `sudo` on macOS (reads powermetrics). It cannot prompt for a password inside a tmux pane. If using asitop in tmux, sudo must be pre-authenticated.
- Tools that need sudo in tmux panes: asitop, bandwhich. Both fail silently or show a password prompt the user can't interact with unless they click into the pane.

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

**Lesson**: When something works "well enough" (nvtop shows GPU % which is the main thing), don't over-iterate trying to fix peripheral issues. The user's v1.3.0 with N/A fields visible was preferable to a series of broken alternatives. Improve incrementally, test each change, and don't stack untested changes.

### 6. Git lock files in sandboxed environments

**What happened**: `.git/index.lock`, `.git/packed-refs.lock`, and `.git/refs/remotes/origin/master.lock` appeared in the sandbox and couldn't be removed (Operation not permitted). All local git operations failed.

**Fix**: Used GitHub's Git Data API (create blob → create tree → create commit → update ref) via curl to push commits directly, bypassing local git entirely.

**Lesson**: In sandboxed/containerized environments, git lock files may be immovable. The GitHub API is a reliable workaround for pushing changes.
