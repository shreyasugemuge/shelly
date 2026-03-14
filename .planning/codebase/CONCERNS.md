# Concerns

## Technical Debt

### Hardcoded Paths
Multiple references to `~/.dotfiles/zsh` throughout the codebase. If the install location changes, these would need updating in several files.
- `install.sh` — symlink source path
- `config/environment.zsh` — PATH references

### Platform Detection Duplication
`$OSTYPE` checks (`[[ "$OSTYPE" == darwin* ]]`) are repeated across multiple config files instead of being centralized into a single variable or function.
- `config/aliases.zsh` — BSD vs GNU `ls` detection
- `config/environment.zsh` — Homebrew path detection
- `config/monitor.zsh` — macmon availability, nvtop config
- `config/sysinfo.zsh` — macOS-specific system info commands

### Legacy Archive Directory
`archive/` contains old bash configs (`.bashrc`, `.bash_profile`, `.bash_aliases`). Preserved for reference but could confuse contributors about what's active.

## Security

### No Input Validation
Shell functions in `config/functions.zsh` (e.g., `mkcd`, `extract`) don't validate inputs. While low-risk for interactive use, could cause unexpected behavior with malicious filenames.

### Eval Usage
NVM lazy-loading in `config/environment.zsh` uses `eval` to source NVM. This is standard practice for NVM but worth noting.

### Unsanitized PATH
PATH is built from multiple sources across `config/environment.zsh` without deduplication. Could accumulate duplicate entries over time.

## Performance

### brew --prefix Calls
Multiple `brew --prefix` invocations during shell startup. Each is a subprocess call. Currently mitigated by lazy-loading (NVM) but could add latency if more are added.

### Compinit Caching
Daily cache strategy for `compinit` works well but could miss plugin changes made mid-day. User must manually `rm ~/.zcompdump*` to force rebuild.

### sysmon Force-Writes
btop and nvtop config files are rewritten on every `sysmon` launch. This is intentional (prevents sticky state bugs) but is technically redundant on repeat launches with no code changes.

## Fragile Areas

### Plugin Sourcing Order
`config/plugins.zsh` — zsh-syntax-highlighting MUST be sourced last. This is a hard zsh requirement. Moving it or adding plugins after it will break highlighting.

### BSD/GNU ls Detection
`config/aliases.zsh` has complex conditional logic to detect BSD vs GNU `ls` for color flags. Easy to break if simplified. CLAUDE.md explicitly warns against this.

### NVM Lazy-Loading
`config/environment.zsh` — Fragile wrapper that intercepts `nvm`, `node`, `npm` commands to defer NVM initialization until first use. If NVM changes its init pattern, this could break silently.

### tmux Pane Layout
`config/monitor.zsh` — Hardcoded pane split percentages (60/40) that may not look right on all terminal sizes or resolutions.

## Known Limitations

### nvtop on Apple Silicon
~80% of fields show N/A (GPU clock, VRAM clock, temperature, fan speed, power draw, PCIe TX/RX). This is a fundamental Apple Metal API limitation, not a bug. Force-written config hides N/A fields.

### sudo in tmux Panes
Tools requiring `sudo` (asitop, bandwhich) cannot prompt for passwords in tmux panes without pre-authentication. This led to removal of both tools from the sysmon dashboard.

### No Automated Tests
All testing is manual. No shellcheck, no CI, no regression tests. Changes rely on developer verification via `exec zsh`.

### Single-User Design
Configuration assumes single-user operation. No multi-user or shared-machine considerations. Machine-specific overrides go in `~/.zshrc.local` (untracked).
