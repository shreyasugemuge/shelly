# Roadmap: Shelly v3.0

**Created:** 2026-03-14
**Milestone:** v3.0 — Dynamic Dev Workspace + Quality Hardening

## Phase Overview

| Phase | Name | Requirements | Status |
|-------|------|-------------|--------|
| 1 | Dynamic devtmux | Complete    | 2026-03-14 |
| 2 | Tech Debt Cleanup | DEBT-01 through DEBT-04 | Not started |
| 3 | QA & Security Audit | QA-01 through QA-05 | Not started |

---

## Phase 1: Dynamic devtmux

**Goal:** Replace hardcoded `devtmux` alias with a dynamic function that lets users pick 1-3 projects and opens a tmux workspace with Claude Code + terminal for each.

**Requirements:** DEV-01, DEV-02, DEV-03, DEV-04, DEV-05, DEV-06, DEV-07, DEV-08, DEV-09, DEV-10

**Plans:** 2/2 plans complete

Plans:
- [x] 01-01-PLAN.md — Implement complete devtmux function in functions.zsh (picker, layout, session mgmt, subcommands)
- [x] 01-02-PLAN.md — Remove old alias from aliases.zsh and human-verify end-to-end workflow

**Key deliverables:**
- `devtmux` function in `config/functions.zsh`
- Code folder detection (`~/code` default, prompt if missing)
- Project picker (fzf with numbered-list fallback)
- tmux layout: N columns, Claude Code top + terminal bottom per column
- Session management (reattach / kill+recreate / `devtmux kill`)
- Cross-platform (macOS + Linux)

**Success criteria:**
- Running `devtmux` shows project picker, selecting 3 projects opens tmux with correct layout
- Claude Code is running in each top pane, terminal prompt in each bottom pane
- Works without fzf installed (falls back to numbered list)
- `devtmux kill` cleanly destroys the session
- No impact on shell startup time

**Depends on:** Nothing

---

## Phase 2: Tech Debt Cleanup

**Goal:** Reduce duplication and fragility in the codebase by centralizing platform detection, deduplicating PATH, and removing hardcoded paths.

**Requirements:** DEBT-01, DEBT-02, DEBT-03, DEBT-04

**Key deliverables:**
- `IS_MACOS` / `IS_LINUX` variables set once, used everywhere
- PATH dedup function or inline logic in `environment.zsh`
- Single `SHELLY_DIR` variable replacing hardcoded `~/.dotfiles/zsh` references
- Verification that all existing functionality still works

**Success criteria:**
- `$OSTYPE` checks appear only once (where `IS_MACOS` is set)
- `echo $PATH | tr ':' '\n' | sort | uniq -d` returns nothing
- grep for `~/.dotfiles/zsh` finds only the variable assignment
- `exec zsh` loads cleanly, sysmon works, all aliases resolve

**Depends on:** Phase 1 (devtmux may use platform detection)

---

## Phase 3: QA & Security Audit

**Goal:** Harden the codebase with linting, input validation, and security review.

**Requirements:** QA-01, QA-02, QA-03, QA-04, QA-05

**Key deliverables:**
- shellcheck audit of all `config/*.zsh` files with fixes or documented exceptions
- Input validation added to shell functions (`mkcd`, `extract`, etc.)
- PATH construction reviewed and hardened
- Plugin sourcing order guard
- Secrets/path audit of all tracked files

**Success criteria:**
- `shellcheck config/*.zsh` passes (or exceptions documented with SC codes)
- Functions handle empty/malicious inputs gracefully
- No machine-specific paths in tracked files
- Plugin sourcing order has a protective comment or runtime check

**Depends on:** Phase 2 (tech debt cleanup may change files that get audited)

---
*Roadmap created: 2026-03-14*
*Last updated: 2026-03-14 after phase 1 complete (plan 01-02)*
