# Shelly — Modular Zsh Configuration

## What This Is

Shelly is a modular zsh configuration by Shreyas Ugemuge. It provides a curated shell environment with custom prompt, system monitoring (`sysmon`), dynamic multi-project dev workspace (`devtmux`), and cross-platform support (macOS, Linux, WSL).

## Core Value

A polished, portable shell environment that just works — with tools like `sysmon` and `devtmux` that eliminate manual tmux setup.

## Requirements

### Validated

- ✓ Modular zsh config with XDG compliance — v1.0
- ✓ Custom prompt with git integration and exit status — v1.0
- ✓ sysmon tmux dashboard (btop + nvtop + macmon) — v1.3.3
- ✓ Cross-platform support (macOS, Linux, WSL) — v2.1.0
- ✓ Dynamic `devtmux` command with interactive project picker — v3.0
- ✓ Tech debt reduction (platform detection, PATH, hardcoded paths) — v3.0
- ✓ QA hardening (shellcheck, input validation, security audit) — v3.0

### Active

<!-- Next milestone scope -->

### Out of Scope

- Remote/SSH dev sessions — complexity, not needed for local workflow
- IDE integration — this is a terminal-first tool
- Project templates or scaffolding — devtmux opens existing projects, doesn't create them
- Re-adding asitop or bandwhich — sudo-in-tmux problem unsolved
- Mobile app or GUI — shell-native

## Context

Shipped v3.0 with 1,359 LOC across 8 zsh modules.
Tech stack: zsh, tmux, brew/apt/dnf/pacman for deps.
All 19 v3.0 requirements complete with zero known gaps.
Enhanced completion system added (zsh-completions, fuzzy matching, tab completion for devtmux/sysmon).

## Constraints

- **Platform**: macOS-first, Linux-compatible — guard platform-specific code
- **Dependencies**: fzf optional (fallback to numbered list)
- **Performance**: No startup impact from devtmux — on-demand command
- **Compatibility**: Separate tmux sessions for dev and sysmon
- **No breaking changes**: Existing aliases, functions, and prompt must continue working

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| fzf with numbered-list fallback | Best UX when available, still works without | ✓ Good |
| Function in functions.zsh, not alias | Dynamic behavior needs a proper function | ✓ Good |
| Session name "dev" (matches current) | User muscle memory, separate from "sysmon" | ✓ Good |
| Up to 3 projects | Matches current workflow, 3 columns fit well | ✓ Good |
| IS_MACOS/IS_LINUX booleans in .zshrc | Eliminates 11 scattered OSTYPE checks | ✓ Good |
| typeset -U path for PATH dedup | Simple, preserves first-occurrence order | ✓ Good |
| Shellcheck inline suppressions | Zero-warning baseline with documented exceptions | ✓ Good |
| Force-write btop/nvtop configs | Prevents sticky state bugs from surviving git reverts | ✓ Good |

---
*Last updated: 2026-03-14 after v3.0 milestone*
