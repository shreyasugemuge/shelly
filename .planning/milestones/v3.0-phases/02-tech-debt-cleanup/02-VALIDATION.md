---
phase: 2
slug: tech-debt-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual — shell configs tested by `exec zsh` |
| **Config file** | None |
| **Quick run command** | `exec zsh` |
| **Full suite command** | `exec zsh && sysmon status && alias | wc -l` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run `exec zsh`
- **After every plan wave:** Run `exec zsh && sysmon status && grep -n 'OSTYPE' config/*.zsh .zshrc`
- **Before `/gsd:verify-work`:** Full verification suite green
- **Max feedback latency:** 3 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | DEBT-01 | smoke | `grep -n 'OSTYPE' config/*.zsh .zshrc` — zero except definition | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | DEBT-02 | smoke | `exec zsh && echo $PATH \| tr ':' '\n' \| sort \| uniq -d` | ✅ | ⬜ pending |
| 02-01-03 | 01 | 1 | DEBT-03 | smoke | `grep -rn '\.dotfiles/zsh' config/ .zshrc` — zero results | ✅ | ⬜ pending |
| 02-01-04 | 01 | 1 | DEBT-04 | smoke | `exec zsh && sysmon status && alias \| wc -l` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. No new test infrastructure needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Shell loads cleanly after all changes | DEBT-04 | Interactive verification | `exec zsh` — no errors, prompt renders correctly |
| sysmon dashboard still works | DEBT-04 | Requires tmux + visual check | `sysmon status` then `sysmon` to verify dashboard |
| devtmux still works | DEBT-04 | Requires interactive testing | `devtmux help` and `devtmux status` |

---

## Validation Sign-Off

- [ ] All tasks have smoke verify commands
- [ ] Sampling continuity: `exec zsh` after every commit
- [ ] No watch-mode flags
- [ ] Feedback latency < 3s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
