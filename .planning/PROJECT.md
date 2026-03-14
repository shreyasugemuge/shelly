# Shelly v3.0 — Dynamic Dev Workspace + Quality Hardening

## What This Is

Shelly is a modular zsh configuration by Shreyas Ugemuge. It provides a curated shell environment with custom prompt, system monitoring (`sysmon`), and development tooling. v3.0 adds a dynamic multi-project dev workspace (`devtmux`) and hardens the codebase with tech debt cleanup and security/QA improvements.

## Core Value

`devtmux` lets you instantly spin up a tmux workspace with Claude Code + terminal for up to 3 projects, selected interactively from your code folder.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Modular zsh config with XDG compliance — v1.0
- ✓ Custom prompt with git integration and exit status — v1.0
- ✓ sysmon tmux dashboard (btop + nvtop + macmon) — v1.3.3
- ✓ Cross-platform support (macOS, Linux, WSL) — v2.1.0

### Active

<!-- Current scope. Building toward these. -->

- [ ] Dynamic `devtmux` command with interactive project picker
- [ ] Tech debt reduction (platform detection, PATH, hardcoded paths)
- [ ] QA hardening (shellcheck, input validation, security audit)

### Out of Scope

- Remote/SSH dev sessions — complexity, not needed for local workflow
- IDE integration — this is a terminal-first tool
- Project templates or scaffolding — devtmux opens existing projects, doesn't create them
- Re-adding asitop or bandwhich — sudo-in-tmux problem unsolved

## Context

- User currently has a hardcoded `devtmux` alias on their Mac that opens 3 specific projects (vipms, vipl-email-agent, erpnext) in tmux with Claude Code
- Layout: 3 vertical columns, each with Claude Code (~85% top) + terminal (~15% bottom), session named "dev"
- Goal is to make this dynamic and portable (part of the repo, not a local alias)
- Codebase map exists at `.planning/codebase/` with 7 analysis documents
- CONCERNS.md identifies 15+ areas for tech debt and security improvement

## Constraints

- **Platform**: macOS-first, Linux-compatible — guard platform-specific code
- **Dependencies**: fzf is optional (fallback to numbered list)
- **Performance**: No startup impact — devtmux is an on-demand command
- **Compatibility**: Must work with existing sysmon tmux session (separate session names)
- **No breaking changes**: Existing aliases, functions, and prompt must continue working

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| fzf with numbered-list fallback | Best UX when available, still works without it | — Pending |
| Function in functions.zsh, not alias | Dynamic behavior needs a proper function | — Pending |
| Session name "dev" (matches current) | User muscle memory, separate from "sysmon" | — Pending |
| Up to 3 projects | Matches current workflow, 3 columns fit well | — Pending |

---
*Last updated: 2026-03-14 after project initialization*
