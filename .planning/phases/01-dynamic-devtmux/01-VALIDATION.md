---
phase: 1
slug: dynamic-devtmux
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual — shell configs tested by `exec zsh` (per project scope) |
| **Config file** | None |
| **Quick run command** | `exec zsh && devtmux help` |
| **Full suite command** | `exec zsh && devtmux status && devtmux help && devtmux kill` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `exec zsh && devtmux help`
- **After every plan wave:** Run full manual checklist against all DEV-0x requirements
- **Before `/gsd:verify-work`:** All requirements manually verified
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | DEV-01 | manual | `exec zsh && devtmux` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | DEV-02 | manual | Set `DEVTMUX_DIR=""` then run `devtmux` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 1 | DEV-03 | manual | Select 4 items in fzf picker | ❌ W0 | ⬜ pending |
| 01-01-04 | 01 | 1 | DEV-04 | manual | Rename fzf, confirm fallback activates | ❌ W0 | ⬜ pending |
| 01-01-05 | 01 | 1 | DEV-05 | manual | `tmux list-panes -t dev` after launch | ❌ W0 | ⬜ pending |
| 01-01-06 | 01 | 1 | DEV-06 | manual | `tmux display-panes -t dev` inspect heights | ❌ W0 | ⬜ pending |
| 01-01-07 | 01 | 1 | DEV-07 | manual | Inspect pane content after session starts | ❌ W0 | ⬜ pending |
| 01-01-08 | 01 | 1 | DEV-08 | manual | Launch `devtmux` twice; verify prompt appears | ❌ W0 | ⬜ pending |
| 01-01-09 | 01 | 1 | DEV-09 | manual | Test on both platforms or verify no OS-specific code | ❌ W0 | ⬜ pending |
| 01-01-10 | 01 | 1 | DEV-10 | smoke | `devtmux kill && tmux ls 2>&1 | grep -v dev` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. All validation is manual via `exec zsh` reload and functional testing. No test framework needed per project scope.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Project picker displays git repos with branches | DEV-03, DEV-04 | Interactive TUI, cannot automate fzf selection | Run `devtmux`, verify git repos listed with branch names |
| Claude Code auto-launches in panes | DEV-07 | Requires visual inspection of tmux panes | Select projects, verify Claude Code header in top panes |
| Reattach/recreate prompt | DEV-08 | Interactive prompt, requires user input | Launch `devtmux` twice, verify prompt appears |
| Layout proportions correct | DEV-06 | Visual inspection of 85/15 split | Launch with 1, 2, 3 projects — check pane heights |
| Cross-platform compatibility | DEV-09 | Requires Linux environment | Review code for `$OSTYPE` guards on macOS-specific commands |

---

## Validation Sign-Off

- [ ] All tasks have manual verify instructions
- [ ] Sampling continuity: `exec zsh && devtmux help` after every commit
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
