---
phase: 01-dynamic-devtmux
verified: 2026-03-14T07:15:00Z
status: human_needed
score: 8/8 must-haves verified
human_verification:
  - test: "Run devtmux and select 1-3 projects — verify correct column layout in tmux"
    expected: "N columns appear, each with an 85% top pane and 15% bottom pane"
    why_human: "Tmux layout geometry can only be confirmed visually; pane size percentages are not inspectable via grep"
  - test: "Verify Claude Code is running in each top pane after project selection"
    expected: "Each top pane shows the Claude Code CLI prompt or loading screen"
    why_human: "send-keys sends 'clear && claude' but whether claude actually starts and displays output cannot be verified without a live session"
  - test: "Verify fzf fallback numbered picker works when fzf is absent"
    expected: "Numbered list of repos prints, user enters space-separated numbers, projects open correctly"
    why_human: "Requires fzf to be uninstalled or the code path to be simulated interactively"
  - test: "Verify magenta status bar label displays project names correctly"
    expected: "Status bar shows 'devtmux | project1, project2' in magenta/purple accent"
    why_human: "Tmux status bar rendering requires a live attached session to observe"
---

# Phase 1: Dynamic devtmux Verification Report

**Phase Goal:** Replace hardcoded `devtmux` alias with a dynamic function that lets users pick 1-3 projects and opens a tmux workspace with Claude Code + terminal for each.
**Verified:** 2026-03-14T07:15:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | devtmux command exists and loads without zsh parse errors | VERIFIED | `zsh -c 'source config/functions.zsh && type devtmux'` returns "devtmux is a shell function from .../config/functions.zsh" |
| 2 | devtmux discovers code folder from $DEVTMUX_DIR or ~/code, prompts if missing | VERIFIED | `_devtmux_get_code_dir()` at line 94: checks `${DEVTMUX_DIR:-$HOME/code}`, prompts on missing path, calls `_devtmux_persist_dir`, exports `DEVTMUX_DIR` |
| 3 | devtmux shows git repos with branch names in fzf or numbered fallback picker | VERIFIED | `_devtmux_pick_projects()` at line 112: builds `repos` array with `"name (branch)"`, fzf path at line 130, numbered fallback at line 142 |
| 4 | devtmux enforces max 3 project selection | VERIFIED | Lines 159-162: `if (( ${#selected[@]} > 3 ))` truncates to first 3 with yellow warning |
| 5 | devtmux builds tmux session with correct column layout and 85/15 splits | VERIFIED (automated) | `_devtmux_build_session()`: `new-session`, horizontal `split-window -h`, `select-layout even-horizontal` once, then `split-window -v -p 15` per column. Visual layout needs human confirmation. |
| 6 | devtmux launches Claude Code in top panes and clears bottom panes | VERIFIED (automated) | Lines 203-212: `send-keys "clear && claude" C-m` on top panes `(i-1)*2`, `send-keys "clear" C-m` on bottom panes `(i-1)*2+1`. Actual execution needs human confirmation. |
| 7 | devtmux reattaches or offers to recreate when session exists | VERIFIED | Lines 307-322: `tmux has-session` guard triggers prompt "[r]eattach or [k]ill and start fresh?", k/K kills and relaunches, any other input reattaches |
| 8 | devtmux uses switch-client when already inside tmux | VERIFIED | Lines 282-286 (`_devtmux_launch`) and 316-319 (reattach path): `if [[ -n "$TMUX" ]]; then tmux switch-client` else `tmux attach-session` |

**Score:** 8/8 truths verified (4 require human confirmation for visual/runtime behavior)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `config/functions.zsh` | Complete devtmux function with all helpers | VERIFIED | 329 lines total; devtmux section starts at line 78. Contains `_DEVTMUX_SESSION`, `_devtmux_persist_dir`, `_devtmux_get_code_dir`, `_devtmux_pick_projects`, `_devtmux_build_session`, `_devtmux_status`, `_devtmux_help`, `_devtmux_launch`, `devtmux` entry point |
| `config/aliases.zsh` | Tmux section without hardcoded devtmux alias | VERIFIED | Only comment reference remains at line 47: `# devtmux moved to config/functions.zsh (v3.0)`. Generic tmux aliases preserved (a_tmux, l_tmux, n_tmux). |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `config/functions.zsh` | tmux | new-session, split-window, select-layout, send-keys | WIRED | Lines 181, 187, 192, 198, 205, 211 all contain the expected tmux subcommands |
| `config/functions.zsh` | fzf | command -v fzf guard with numbered fallback | WIRED | Line 130: `if command -v fzf &>/dev/null` guards fzf path; lines 142-156 provide complete numbered fallback |
| `config/functions.zsh` | ~/.zshrc.local | `_devtmux_persist_dir` appending DEVTMUX_DIR | WIRED | Lines 86-89: grep-q duplicate guard then `echo "export DEVTMUX_DIR..." >> "$local_rc"` |
| `.zshrc` | `config/functions.zsh` | source via ZDOTDIR_CUSTOM at shell startup | WIRED | `.zshrc` line 26: `"$ZDOTDIR_CUSTOM/functions.zsh"` in the source loop; deployed copy at `~/.config/zsh/functions.zsh` is byte-for-byte identical to repo |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DEV-01 | 01-01-PLAN.md | `devtmux` command launches interactive project selection workflow | SATISFIED | `devtmux` function exists, `_devtmux_launch` calls picker |
| DEV-02 | 01-01-PLAN.md | Auto-detects `~/code` as default code folder, prompts if not found | SATISFIED | `_devtmux_get_code_dir()` uses `${DEVTMUX_DIR:-$HOME/code}` with prompt fallback |
| DEV-03 | 01-01-PLAN.md | User can select 1-3 projects from code folder subdirectories | SATISFIED | Max-3 enforcement at lines 159-162 |
| DEV-04 | 01-01-PLAN.md | Project picker uses fzf when available, falls back to numbered list | SATISFIED | `command -v fzf` guard at line 130 with complete numbered fallback |
| DEV-05 | 01-01-PLAN.md | Opens tmux session "dev" with one column per selected project | SATISFIED | `_DEVTMUX_SESSION="dev"`, horizontal splits loop for each project |
| DEV-06 | 01-01-PLAN.md | Each column has Claude Code pane (~85% top) and terminal pane (~15% bottom) | SATISFIED (needs human) | `split-window -v -p 15` creates 15% bottom pane; visual confirmation needed |
| DEV-07 | 01-01-PLAN.md | Claude Code auto-launches in each project's directory | SATISFIED (needs human) | `send-keys "clear && claude" C-m` on each top pane; runtime confirmation needed |
| DEV-08 | 01-01-PLAN.md | Reattaches to existing "dev" session, or offers to kill and recreate | SATISFIED | Prompt + k/K kill path at lines 307-322 |
| DEV-09 | 01-01-PLAN.md | Works on macOS and Linux | SATISFIED | No macOS-only tmux flags; `git rev-parse` (POSIX); `tput` (POSIX); no `$OSTYPE` guards in devtmux section |
| DEV-10 | 01-02-PLAN.md | `devtmux kill` tears down the dev session | SATISFIED | Lines 292-298: `tmux kill-session` with `has-session` guard and green/gray status messages |

All 10 requirements (DEV-01 through DEV-10) accounted for. No orphaned requirements.

---

### Anti-Patterns Found

No TODO, FIXME, PLACEHOLDER, or stub patterns found in `config/functions.zsh` or `config/aliases.zsh`.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | None found | — | — |

---

### Human Verification Required

The automated checks confirm all code paths exist and are wired correctly. The following items require a live shell session to confirm runtime behavior:

#### 1. Tmux layout geometry

**Test:** Run `devtmux`, select 2-3 projects, observe the resulting tmux session
**Expected:** N columns of equal width, each with a large top pane (~85%) running Claude Code and a small bottom pane (~15%) with a clean terminal prompt
**Why human:** Pane percentages and column layout are visual; `split-window -v -p 15` sets intent but actual pixel/cell geometry requires observation

#### 2. Claude Code launch in top panes

**Test:** After `devtmux` opens a session, inspect each top pane
**Expected:** Each top pane is in the project's directory and showing the Claude Code CLI interface (not just a cleared terminal)
**Why human:** `send-keys "clear && claude" C-m` fires a keypress but whether `claude` is installed, in PATH, and launches successfully can only be confirmed in a live session

#### 3. Numbered fallback picker (without fzf)

**Test:** Temporarily rename/remove fzf or test in an environment without it, run `devtmux`, enter numbers when prompted
**Expected:** Numbered list of git repos prints, space-separated input accepted, selected projects open correctly
**Why human:** Requires simulating the absence of fzf and interactive terminal input

#### 4. Magenta status bar appearance

**Test:** After `devtmux` opens a session, observe the tmux status bar
**Expected:** Status bar shows `devtmux | project-a, project-b` in magenta/purple accent colors (colour135, colour183), distinct from sysmon's amber
**Why human:** Terminal color rendering requires visual inspection

---

### Summary

All 8 observable truths verified at the code level. All 10 requirements (DEV-01–DEV-10) are implemented and wired. No stub patterns or anti-patterns detected. The deployed copy at `~/.config/zsh/functions.zsh` is identical to the repo source. The hardcoded alias is fully removed from `config/aliases.zsh` with only a migration comment remaining.

The 4 items flagged for human verification are all runtime/visual behaviors (layout geometry, Claude launch, color rendering, interactive picker fallback) that cannot be confirmed without a live session. The automated evidence strongly supports they will work as intended.

---

_Verified: 2026-03-14T07:15:00Z_
_Verifier: Claude (gsd-verifier)_
