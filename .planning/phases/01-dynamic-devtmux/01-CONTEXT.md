# Phase 1: Dynamic devtmux - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the hardcoded `devtmux` alias in `config/aliases.zsh` with a dynamic `devtmux` function. Users interactively pick 1-3 projects from their code folder, and a tmux session opens with Claude Code + terminal pane per project. Includes subcommands (kill, status, help) following the sysmon pattern.

</domain>

<decisions>
## Implementation Decisions

### Project Picker UX
- Show git repos only (directories containing `.git`) — filter out non-repo folders
- Display project name + current git branch, e.g. `vipms (main)`
- Use fzf multi-select when available: Tab to mark items, Enter to confirm
- If more than 3 selected, take first 3 and print warning: "Max 3 projects — using first 3"
- Fallback to numbered list when fzf is not installed — user types numbers separated by spaces

### Session Handling
- When "dev" session already exists: prompt user "Reattach or start fresh?"
- If already inside tmux (e.g. sysmon): use `tmux switch-client` to move to dev session — no nesting
- Full subcommand set mirroring sysmon: `devtmux kill`, `devtmux status`, `devtmux help`
- `devtmux status` shows: which projects are open, session state, fzf availability

### Code Folder Discovery
- Default to `~/code` — check if directory exists
- If `~/code` doesn't exist: prompt user for code folder path
- Persist chosen path by appending `export DEVTMUX_DIR="/path/to/code"` to `~/.zshrc.local`
- On subsequent runs: check `$DEVTMUX_DIR` first, fall back to `~/code`

### Layout & Scaling
- 85/15 vertical split per column: Claude Code pane on top (~85%), terminal on bottom (~15%)
- Scale columns to selection count: 1 project = full width, 2 = 50/50, 3 = 33/33/33
- Use `select-layout even-horizontal` for equal column widths (matches current alias)
- Status bar: distinct from sysmon — magenta/purple accent (sysmon uses amber)
- Status bar shows session label "devtmux" + project names
- Mouse enabled for pane switching/resizing

### Claude's Discretion
- Exact fzf flags and configuration
- Numbered list prompt formatting
- Error message wording
- Helper function naming (_devtmux_* prefix pattern)
- How to handle edge case: code folder exists but has no git repos

</decisions>

<specifics>
## Specific Ideas

- Current alias at `config/aliases.zsh:47-60` — runs `clear && claude` in top panes, `clear` in bottom panes
- Follow sysmon's architecture: session constant, helper functions with `_` prefix, main entry point with case statement
- The function should live in `config/functions.zsh` (not monitor.zsh, which is sysmon-specific)
- Remove the old hardcoded alias from `config/aliases.zsh` when the function is added

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sysmon` in `config/monitor.zsh`: Reference architecture for tmux session management, subcommands, status checks, dep installation, pane layout
- `_sysmon_pkg_install()`: Package manager detection pattern (brew/apt/dnf/pacman) — though fzf is optional, not required
- Tmux alias patterns in `config/aliases.zsh:44-46`: `a_tmux`, `l_tmux`, `n_tmux`

### Established Patterns
- Session name as module constant: `_SYSMON_SESSION="sysmon"` → `_DEVTMUX_SESSION="dev"`
- Entry point with case/esac for subcommands (kill, status, help, default)
- Helper functions prefixed with `_` (e.g., `_sysmon_launch`, `_sysmon_status`)
- Error messages: colored symbols (`✓`, `✗`, `·`) with escape codes

### Integration Points
- Function goes in `config/functions.zsh` (sourced by `.zshrc`)
- Remove alias from `config/aliases.zsh:47-60`
- `~/.zshrc.local` for persisting DEVTMUX_DIR (already sourced by `.zshrc`)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-dynamic-devtmux*
*Context gathered: 2026-03-14*
