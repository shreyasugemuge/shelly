---
phase: 03
slug: qa-security-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (exec zsh) + shellcheck CLI — automated test framework is out of scope |
| **Config file** | `.shellcheckrc` (Wave 0 creates at repo root) |
| **Quick run command** | `exec zsh` (reload shell, check for errors) |
| **Full suite command** | `shellcheck --shell=bash config/*.zsh && exec zsh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `exec zsh`
- **After every plan wave:** Run `shellcheck --shell=bash config/*.zsh && exec zsh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | QA-01 | smoke | `shellcheck --shell=bash config/*.zsh` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | QA-02 | manual | `portfind abc; portfind 99999; portfind 80` | N/A | ⬜ pending |
| 03-01-03 | 01 | 1 | QA-02 | manual | `mkcd; mkcd /tmp/test-mkcd-$$` | N/A | ⬜ pending |
| 03-01-04 | 01 | 1 | QA-03 | manual | `exec zsh; echo $PATH \| tr ':' '\n' \| sort \| uniq -d` | N/A | ⬜ pending |
| 03-01-05 | 01 | 1 | QA-04 | smoke | `grep -n 'SOURCING ORDER GUARD' config/plugins.zsh` | ❌ W0 | ⬜ pending |
| 03-01-06 | 01 | 1 | QA-05 | smoke | `git ls-files \| xargs grep -l '/Users/' -- \| grep -v CHANGELOG` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `shellcheck` binary — install via `brew install shellcheck` before any QA-01 work
- [ ] `.shellcheckrc` at repo root — create with `shell=bash` before running batch audit

*No test file gaps — validation is manual + shellcheck CLI, not a test framework*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| portfind rejects non-numeric/out-of-range ports | QA-02 | Interactive shell function | Run `portfind abc`, `portfind 99999`, `portfind 80` — first two should error, third should work |
| mkcd handles empty input | QA-02 | Interactive shell function | Run `mkcd` with no args — should show usage/error, not fail silently |
| PATH has no duplicates | QA-03 | Requires shell reload | `exec zsh` then `echo $PATH \| tr ':' '\n' \| sort \| uniq -d` — should print nothing |
| Shell loads cleanly after all changes | QA-01 | Requires interactive terminal | `exec zsh` — no errors or warnings |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
