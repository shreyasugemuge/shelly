# Requirements: Shelly v3.0

**Defined:** 2026-03-14
**Core Value:** Dynamic multi-project dev workspace with Claude Code

## v3.0 Requirements

### Dev Workspace (devtmux)

- [ ] **DEV-01**: `devtmux` command launches interactive project selection workflow
- [ ] **DEV-02**: Auto-detects `~/code` as default code folder, prompts if not found
- [ ] **DEV-03**: User can select 1-3 projects from code folder subdirectories
- [ ] **DEV-04**: Project picker uses fzf when available, falls back to numbered list
- [ ] **DEV-05**: Opens tmux session "dev" with one column per selected project
- [ ] **DEV-06**: Each column has Claude Code pane (~85% top) and terminal pane (~15% bottom)
- [ ] **DEV-07**: Claude Code auto-launches in each project's directory
- [ ] **DEV-08**: Reattaches to existing "dev" session, or offers to kill and recreate
- [ ] **DEV-09**: Works on macOS and Linux
- [ ] **DEV-10**: `devtmux kill` tears down the dev session

### Tech Debt Cleanup

- [ ] **DEBT-01**: Platform detection centralized (single `IS_MACOS` variable or function)
- [ ] **DEBT-02**: PATH deduplication prevents duplicate entries
- [ ] **DEBT-03**: Hardcoded `~/.dotfiles/zsh` references use a single variable
- [ ] **DEBT-04**: No regressions — all existing functionality preserved

### QA & Security

- [ ] **QA-01**: shellcheck passes on all config/*.zsh files (or documented exceptions)
- [ ] **QA-02**: Shell functions validate inputs (mkcd, extract, etc.)
- [ ] **QA-03**: PATH construction audited and hardened
- [ ] **QA-04**: Plugin sourcing order enforced with guard comment or check
- [ ] **QA-05**: No secrets or machine-specific paths in tracked files

## Out of Scope

| Feature | Reason |
|---------|--------|
| Project-specific Claude prompts | Scope creep — devtmux opens Claude, doesn't configure it |
| Persistent code folder config file | Over-engineering — env var or default is sufficient |
| More than 3 projects | Screen real estate limit, matches current workflow |
| CI pipeline | Not needed for a dotfiles repo at this stage |
| Automated test framework | Shell configs tested manually via `exec zsh` |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEV-01 | Phase 1 | Pending |
| DEV-02 | Phase 1 | Pending |
| DEV-03 | Phase 1 | Pending |
| DEV-04 | Phase 1 | Pending |
| DEV-05 | Phase 1 | Pending |
| DEV-06 | Phase 1 | Pending |
| DEV-07 | Phase 1 | Pending |
| DEV-08 | Phase 1 | Pending |
| DEV-09 | Phase 1 | Pending |
| DEV-10 | Phase 1 | Pending |
| DEBT-01 | Phase 2 | Pending |
| DEBT-02 | Phase 2 | Pending |
| DEBT-03 | Phase 2 | Pending |
| DEBT-04 | Phase 2 | Pending |
| QA-01 | Phase 3 | Pending |
| QA-02 | Phase 3 | Pending |
| QA-03 | Phase 3 | Pending |
| QA-04 | Phase 3 | Pending |
| QA-05 | Phase 3 | Pending |

**Coverage:**
- v3.0 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 after initial definition*
