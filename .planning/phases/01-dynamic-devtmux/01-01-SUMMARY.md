---
phase: 01-dynamic-devtmux
plan: 01
subsystem: shell-functions
tags: [zsh, tmux, fzf, devtools, workspace]

# Dependency graph
requires: []
provides:
  - "devtmux function in config/functions.zsh with all 9 components"
  - "fzf multi-select project picker with numbered fallback"
  - "dynamic tmux session builder for 1-3 projects"
  - "session reattach/recreate prompt flow"
  - "DEVTMUX_DIR persistence to ~/.zshrc.local"
affects:
  - "01-02 (alias removal plan — depends on devtmux function existing)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "_devtmux_* helper prefix convention (mirrors _sysmon_* pattern)"
    - "fzf --multi with numbered fallback via command -v guard"
    - "dynamic tmux layout: horizontal splits first, even-horizontal once, then vertical splits"
    - "pane index formula: top pane = (i-1)*2, bottom pane = (i-1)*2+1 (1-based zsh loop)"

key-files:
  created: []
  modified:
    - "config/functions.zsh"

key-decisions:
  - "Used (i-1)*2 pane index formula with 1-based zsh loop (for (( i=1; i<=count; i++ ))) to avoid off-by-one errors"
  - "select-layout even-horizontal called exactly once after all horizontal splits, before any vertical splits (per Pitfall 3)"
  - "stderr used for all error/warning messages in helpers so stdout captures only project names"
  - "Task 2 was a pure verification pass — no code changes required (all session behaviors were correct in Task 1)"

patterns-established:
  - "Pattern: fzf guard with numbered fallback — use command -v fzf &>/dev/null before any fzf call"
  - "Pattern: tmux pane index after mixed splits — N columns yields top panes at (N-1)*2 and bottom at (N-1)*2+1"
  - "Pattern: persist env var to ~/.zshrc.local with duplicate guard via grep -q before appending"

requirements-completed: [DEV-01, DEV-02, DEV-03, DEV-04, DEV-05, DEV-06, DEV-07, DEV-08, DEV-09]

# Metrics
duration: 2min
completed: 2026-03-14
---

# Phase 1 Plan 01: Implement devtmux Function Summary

**Dynamic multi-project dev workspace launcher with fzf picker, code folder discovery, 85/15 tmux column layout, and session reattach/recreate flow**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-14T06:48:02Z
- **Completed:** 2026-03-14T06:49:20Z
- **Tasks:** 2 (Task 2 was verification-only, no code changes)
- **Files modified:** 1

## Accomplishments

- Complete `devtmux` function with all 9 components loaded and verified without parse errors
- fzf multi-select picker with graceful numbered fallback, max-3 enforcement, branch display stripped for directory use
- Dynamic tmux session builder: loop-based horizontal splits, single `select-layout even-horizontal`, then 15% vertical splits per column with `clear && claude` in top panes
- Session management: reattach/recreate prompt, `switch-client` vs `attach-session` based on `$TMUX`, kill subcommand
- DEVTMUX_DIR persisted to `~/.zshrc.local` with duplicate-guard

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement devtmux helper functions** - `ab6a89f` (feat)
2. **Task 2: Session reattach/recreate flow** - no-op verification, no commit needed

## Files Created/Modified

- `/Users/uge/code/shelly/config/functions.zsh` - Added 252 lines: `_DEVTMUX_SESSION` constant, `_devtmux_persist_dir`, `_devtmux_get_code_dir`, `_devtmux_pick_projects`, `_devtmux_build_session`, `_devtmux_status`, `_devtmux_help`, `_devtmux_launch`, and `devtmux` entry point

## Decisions Made

- Used 1-based zsh loop (`for (( i=1; i<=count; i++ ))`) with `(i-1)*2` pane index formula to match RESEARCH.md recommendation and avoid off-by-one errors that would send `claude` to wrong panes
- stderr (`>&2`) used for all error/warning prints in helper functions so `$()` capture only receives the directory path or project names
- Task 2 required zero code changes — all session handling behaviors (reattach prompt, kill+recreate, switch-client vs attach-session, no-session path) were correctly implemented in Task 1

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. `~/.zshrc.local` is written only when DEVTMUX_DIR needs to be persisted (on first run when `~/code` doesn't exist).

## Next Phase Readiness

- `devtmux` function fully operational — Plan 02 can proceed to remove the hardcoded alias from `config/aliases.zsh` (lines 47-60)
- No blockers

## Self-Check: PASSED

- config/functions.zsh: FOUND
- 01-01-SUMMARY.md: FOUND
- commit ab6a89f: FOUND

---
*Phase: 01-dynamic-devtmux*
*Completed: 2026-03-14*
