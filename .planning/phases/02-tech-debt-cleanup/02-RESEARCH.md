# Phase 2: Tech Debt Cleanup - Research

**Researched:** 2026-03-14
**Domain:** Zsh shell configuration — platform detection, PATH management, hardcoded path cleanup
**Confidence:** HIGH

## Summary

Phase 2 is a pure refactoring pass with no new features. The codebase has three localized, well-understood problems: (1) `$OSTYPE` is checked eleven times across five files instead of once; (2) PATH has no deduplication, so repeated `exec zsh` or nested shell spawning can accumulate duplicates; (3) the conventional install path `~/.dotfiles/zsh` appears in documentation and README prose but not inside the `.zsh` config files themselves — the configs already use symlink-agnostic paths (`ZDOTDIR_CUSTOM`, `REPO_DIR`, `XDG_*`). This distinction is important: DEBT-03 is smaller in scope than the REQUIREMENTS.md wording implies.

DEBT-04 (no regressions) is not a feature but a gate: every other task must leave `exec zsh` clean, sysmon working, and all aliases resolving.

**Primary recommendation:** Add `IS_MACOS` and `IS_LINUX` boolean variables to `environment.zsh` at the top, replace all raw `$OSTYPE` checks with them codebase-wide, add a one-line PATH dedup at the end of `environment.zsh`, and update the README clone example to reflect that the install path is the user's choice (or document `SHELLY_DIR` as a variable in the README). No config files inside `config/*.zsh` contain hardcoded `~/.dotfiles/zsh`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DEBT-01 | Platform detection centralized (single `IS_MACOS` variable or function) | 11 raw `$OSTYPE` checks across 5 files; centralizing to 2 variables in `environment.zsh` removes all redundancy |
| DEBT-02 | PATH deduplication prevents duplicate entries | Only one `export PATH=` line exists in the codebase (NVM node in `environment.zsh`); system-level duplicates from repeated sourcing require a dedup pass at environment setup time |
| DEBT-03 | Hardcoded `~/.dotfiles/zsh` references use a single variable | References live in README.md and CLAUDE.md docs only — not in `.zsh` config files; scope is documentation cleanup, not code refactoring |
| DEBT-04 | No regressions — all existing functionality preserved | Verification gate: `exec zsh` must load cleanly, all aliases must resolve, sysmon must launch |
</phase_requirements>

## Standard Stack

### Core (already in use — no new dependencies)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| zsh | system | Shell runtime for all config | Project target shell |
| `$OSTYPE` | built-in | Platform detection variable | Zsh built-in, always available, no subshell cost |
| `typeset -U` | built-in | Array deduplication in zsh | The canonical zsh idiom for unique-path arrays |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `IS_MACOS` boolean variable | `is_macos()` function | Function call overhead on every check; variable read is zero-cost |
| `typeset -U path` | Custom dedup function | `typeset -U` is idiomatic zsh and requires one line; custom is redundant |
| `IS_MACOS` / `IS_LINUX` booleans | `IS_PLATFORM` string enum | Two booleans are clearer to read in conditionals; string comparison is more error-prone |

## Architecture Patterns

### Recommended Project Structure
No structure changes — all changes are edits within existing files.

```
config/
├── environment.zsh   # ADD: IS_MACOS, IS_LINUX, PATH dedup at bottom
├── aliases.zsh       # REPLACE: $OSTYPE check with IS_MACOS
├── functions.zsh     # REPLACE: two $OSTYPE checks with IS_MACOS
├── deps.zsh          # REPLACE: two $OSTYPE checks with IS_MACOS
├── monitor.zsh       # REPLACE: five $OSTYPE checks with IS_MACOS
└── sysinfo.zsh       # REPLACE: two $OSTYPE checks with IS_MACOS
```

```
README.md            # CLARIFY: clone path is user's choice, not hardcoded
```

### Pattern 1: Centralized Platform Detection Variables

**What:** Set `IS_MACOS` and `IS_LINUX` once at the top of `environment.zsh`. All other files use these variables in place of raw `$OSTYPE` checks.

**When to use:** Anywhere that currently has `[[ "$OSTYPE" == darwin* ]]`.

**Example:**
```zsh
# In environment.zsh — near the top, before other platform-conditional code

[[ "$OSTYPE" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
[[ "$OSTYPE" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false

# Then everywhere else:
if $IS_MACOS; then
    # macOS-specific code
else
    # Linux fallback
fi
```

**Why boolean variables, not a function:** Variable reads are zero-cost and available immediately in all sourced files. Functions need a subshell or call overhead on every check. This matches the project's performance-first philosophy.

**Why `$IS_MACOS` and not `$IS_LINUX` alone:** The codebase has two distinct branches — darwin behavior and linux behavior. Two explicit booleans make conditions read naturally. A single variable would require negation (`! $IS_MACOS`) which is less readable.

**Naming convention:** Uppercase, underscore-prefixed would be `_IS_MACOS` per the internal convention, but since these are intended to be available to all sourced modules (not just local to one file), non-prefixed uppercase is correct — matching `EDITOR`, `NVM_DIR`, etc.

### Pattern 2: Zsh Typeset-U PATH Deduplication

**What:** Use `typeset -U path` (lowercase `path` is the zsh array mirror of `$PATH`) to enforce uniqueness. Applied once at the end of `environment.zsh`.

**When to use:** After all PATH modifications in `environment.zsh`.

**Example:**
```zsh
# At the bottom of environment.zsh, after all PATH mutations:

# Deduplicate PATH — zsh's typeset -U removes duplicate entries
# from the path array (the array form of $PATH), preserving order.
typeset -U path
export PATH
```

**Why `typeset -U path` not a custom loop:** This is the canonical zsh idiom. It handles the `path` array (zsh's linked representation of `$PATH`) in one line, preserves first-occurrence order, and costs nothing at runtime beyond the single typeset call.

**Scope of the problem:** Currently only one `export PATH=` line exists in the codebase (`environment.zsh` line 46, for NVM node). However, system-level PATH entries from `/etc/zprofile`, `/etc/paths`, or Homebrew init can cause duplicates when shells are nested (e.g., `exec zsh` from inside tmux). The dedup call prevents accumulation.

### Pattern 3: README Clone Path Clarification (DEBT-03)

**What:** The `~/.dotfiles/zsh` reference in README.md is a recommended convention, not a hardcoded path in the code. The config files use `REPO_DIR` (computed dynamically in `install.sh`) and `ZDOTDIR_CUSTOM` (XDG-derived). The README clone example should note the path is user-chosen.

**When to use:** README.md Quick Start section.

**What to change:** Add a note that `~/.dotfiles/zsh` is the conventional location used in examples and that any path works. Optionally introduce a `SHELLY_DIR` mention so users understand the concept. No `.zsh` file changes needed for DEBT-03.

**Important:** Do not introduce a `SHELLY_DIR` variable into `.zsh` config files unless a real runtime need is found — the codebase does not reference `~/.dotfiles/zsh` at runtime, only in docs.

### Anti-Patterns to Avoid

- **Replacing `$OSTYPE` with a function call:** `is_macos()` requires a subshell or command substitution on each use. Variables are zero-cost. The project already optimizes startup time aggressively (lazy NVM, cached compinit).
- **Using `export IS_MACOS=true`:** Exporting to child processes is unnecessary and pollutes the environment. Use plain assignment: `IS_MACOS=true`.
- **Moving the dedup call before PATH mutations:** `typeset -U path` must come after all PATH mutations, otherwise freshly added paths won't be deduplicated.
- **Changing the `$OSTYPE` check in `deps.zsh` for Homebrew path detection:** The deps.zsh Homebrew check is already correct and functional. Replace the `$OSTYPE` comparison but do not change its logic.
- **Touching `aliases.zsh` BSD/GNU ls detection:** CLAUDE.md explicitly warns "don't simplify it." The platform variable refactor only replaces `$OSTYPE` — the ls conditional logic stays identical.
- **Adding `IS_MACOS` to `.zshrc` directly:** It belongs in `environment.zsh` which is sourced second (after deps). Since deps.zsh also has `$OSTYPE` checks, a risk exists: deps.zsh runs before environment.zsh. See Pitfall 1 below.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PATH deduplication | Custom loop comparing entries | `typeset -U path` | Built into zsh; order-preserving; one line |
| Platform detection | Function that runs `uname` | `$OSTYPE` variable | Already set by zsh before any config runs; zero cost |

**Key insight:** Zsh provides both of the primitives needed for this phase as built-ins. Writing custom code for either would be redundant and slower.

## Common Pitfalls

### Pitfall 1: deps.zsh Runs Before environment.zsh — IS_MACOS Not Yet Set
**What goes wrong:** If `IS_MACOS` is defined in `environment.zsh` and `deps.zsh` runs first (it does — see `.zshrc` sourcing order), then `deps.zsh` cannot use `IS_MACOS`. If a naïve implementation replaces `$OSTYPE` checks in deps.zsh with `$IS_MACOS` references, those will be empty and the checks will silently fail.

**Why it happens:** `.zshrc` sources `deps.zsh` first, then `environment.zsh`. This is intentional — deps installs plugins before they are loaded.

**How to avoid:** Two options:
1. Keep the raw `$OSTYPE` check in deps.zsh as-is (acceptable — DEBT-01 says "centralized", not "every file must use the variable").
2. Set `IS_MACOS` in `.zshrc` before the sourcing loop, then use it everywhere including deps.zsh.

**Recommended:** Option 2. Set `IS_MACOS` and `IS_LINUX` at the very top of `.zshrc`, before the sourcing loop. Then reference these in all modules including deps.zsh. This is the cleanest centralization.

**Warning signs:** `deps.zsh` not installing brew on macOS, `_install_plugins` taking the Linux apt branch on macOS.

### Pitfall 2: `typeset -U path` Must Use Lowercase `path`
**What goes wrong:** `typeset -U PATH` (uppercase) does not work as expected — `PATH` is a string, not a zsh array. The array form is lowercase `path`.

**Why it happens:** Zsh has a "tied" relationship between `$PATH` (colon-separated string) and `$path` (array). `typeset -U` works on arrays only.

**How to avoid:** Use `typeset -U path` (lowercase). The change is reflected in `$PATH` automatically.

**Warning signs:** `echo $PATH | tr ':' '\n' | sort | uniq -d` still shows duplicates after the dedup call.

### Pitfall 3: Replacing `$OSTYPE` Checks Without Verifying All 11 Occurrences
**What goes wrong:** Grep finds most occurrences but misses one in a different file, leaving a mixed state (some files use `IS_MACOS`, one still uses raw `$OSTYPE`).

**Why it happens:** Manual search and replace across multiple files.

**How to avoid:** After the refactor, run `grep -n 'OSTYPE' config/*.zsh` and verify zero results (or only the single definition site).

**Warning signs:** shellcheck or manual review shows lingering `$OSTYPE` == darwin in non-environment files.

### Pitfall 4: DEBT-03 Scope Creep — Introducing SHELLY_DIR Into Runtime Config
**What goes wrong:** DEBT-03 sounds like a code change but the actual hardcoded path only appears in README.md and CLAUDE.md. Adding a `SHELLY_DIR` variable to `.zsh` config files is over-engineering — the runtime already uses `ZDOTDIR_CUSTOM` (XDG-derived) and `REPO_DIR` (dynamically computed in `install.sh`).

**Why it happens:** The REQUIREMENTS.md wording ("use a single variable") implies a code variable. But inspection shows no `.zsh` file contains `~/.dotfiles/zsh`.

**How to avoid:** Verify with `grep -rn '\.dotfiles/zsh' config/ .zshrc` before implementing. If grep returns nothing, DEBT-03 is a README documentation task only.

**Warning signs:** Adding unreferenced variables to `environment.zsh` for cosmetic reasons.

### Pitfall 5: Breaking the `ls` Alias Platform Detection
**What goes wrong:** The `ls` alias in `aliases.zsh` uses a runtime test (`ls --color=auto /dev/null &>/dev/null`) rather than an `$OSTYPE` check to detect BSD vs GNU ls. This is intentional — the test checks actual capability, not assumed platform. CLAUDE.md says "don't simplify it."

**Why it happens:** Temptation to replace all platform checks with `IS_MACOS`.

**How to avoid:** Do not change the `ls` alias logic. It is not an `$OSTYPE` check and should not become one.

## Code Examples

Verified patterns from official sources (zsh documentation and codebase):

### IS_MACOS / IS_LINUX Declaration (top of .zshrc)
```zsh
# ── Platform Detection ──
# Set once here, used in all sourced modules.
# deps.zsh is sourced first, so these must be defined before the sourcing loop.
[[ "$OSTYPE" == darwin* ]] && IS_MACOS=true || IS_MACOS=false
[[ "$OSTYPE" == linux*  ]] && IS_LINUX=true  || IS_LINUX=false
```

### Replacing a Raw OSTYPE Check (example from functions.zsh)
```zsh
# Before:
if [[ "$OSTYPE" == darwin* ]]; then
    man -t "$1" | open -f -a /Applications/Preview.app
else
    echo "pan: this function requires macOS Preview.app"

# After:
if $IS_MACOS; then
    man -t "$1" | open -f -a /Applications/Preview.app
else
    echo "pan: this function requires macOS Preview.app"
```

### PATH Deduplication (end of environment.zsh)
```zsh
# ── PATH Deduplication ──
# Remove duplicate entries; preserves first-occurrence order.
typeset -U path
export PATH
```

### Verification Commands (success criteria from ROADMAP.md)
```zsh
# No duplicate PATH entries:
echo $PATH | tr ':' '\n' | sort | uniq -d

# No raw OSTYPE checks remain in config files (except definition site):
grep -n 'OSTYPE' config/*.zsh .zshrc

# No hardcoded dotfiles paths in tracked zsh files:
grep -rn '\.dotfiles/zsh' config/ .zshrc
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw `$OSTYPE` check in each file | `IS_MACOS` variable set once | This phase | Removes 11 redundant checks; single source of truth |
| No PATH dedup | `typeset -U path` | This phase | Prevents duplicate PATH entries in nested shells |
| `~/.dotfiles/zsh` in README as hardcoded | Clarified as conventional/user-chosen path | This phase | Docs accurately reflect that install path is flexible |

**No deprecations:** Nothing is removed; existing `$OSTYPE` checks are replaced in-place with the new variable.

## Open Questions

1. **Where exactly to put IS_MACOS — `.zshrc` vs `environment.zsh`?**
   - What we know: `deps.zsh` runs before `environment.zsh`, so if defined in `environment.zsh` only, deps.zsh cannot use it.
   - What's unclear: Whether deps.zsh actually benefits from using `IS_MACOS` (it has two `$OSTYPE` checks).
   - Recommendation: Define in `.zshrc` before the sourcing loop. This is the cleanest centralization and covers all modules including deps.zsh.

2. **Should IS_MACOS be exported or unexported?**
   - What we know: Child processes (tmux panes, subshells) don't need it — they re-source the config. Exported variables pollute the environment unnecessarily.
   - Recommendation: Plain assignment (`IS_MACOS=true`), not `export`. Consistent with `_SYSMON_SESSION`, `_DEVTMUX_SESSION` which are also unexported.

3. **Does DEBT-03 require any code change at all?**
   - What we know: `grep -rn '\.dotfiles/zsh' config/ .zshrc` returns zero results. The reference is in README.md and CLAUDE.md only.
   - Recommendation: DEBT-03 = README.md edit only. Confirm with grep before implementation. If a planner wants to add a `SHELLY_DIR` variable for documentation completeness, it should only be a README clarification, not a `.zsh` file variable.

## Validation Architecture

> `workflow.nyquist_validation` is absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual (no automated test framework — see REQUIREMENTS.md Out of Scope) |
| Config file | none |
| Quick run command | `exec zsh` (reload shell, check for errors) |
| Full suite command | `exec zsh && sysmon status && alias \| wc -l` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEBT-01 | `IS_MACOS` is set and used everywhere `$OSTYPE` was | manual-smoke | `grep -n 'OSTYPE' config/*.zsh .zshrc` — should show zero results except the definition | ✅ files exist, command is ad-hoc |
| DEBT-02 | No duplicate PATH entries after shell reload | manual-smoke | `exec zsh && echo $PATH \| tr ':' '\n' \| sort \| uniq -d` — should print nothing | ✅ files exist, command is ad-hoc |
| DEBT-03 | No hardcoded `~/.dotfiles/zsh` in tracked zsh files | manual-smoke | `grep -rn '\.dotfiles/zsh' config/ .zshrc` — should print nothing | ✅ already passes (no hardcoded refs in .zsh files) |
| DEBT-04 | Shell loads cleanly, sysmon works, all aliases resolve | manual-smoke | `exec zsh` produces no errors; `sysmon status` runs; `alias` lists expected aliases | ✅ files exist |

**Note on manual-only justification:** The project explicitly lists "Automated test framework — Shell configs tested manually via `exec zsh`" as out of scope. All tests here are interactive verification steps, not automated CI.

### Sampling Rate
- **Per task commit:** `exec zsh` — reload shell and visually check for errors
- **Per wave merge:** `exec zsh && sysmon status && grep -n 'OSTYPE' config/*.zsh .zshrc`
- **Phase gate:** Full verification suite green before `/gsd:verify-work`

### Wave 0 Gaps
None — no new test infrastructure is needed. All verification is ad-hoc shell commands.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — all 8 config files and `.zshrc` read in full
- `.planning/codebase/CONCERNS.md` — pre-existing tech debt enumeration verified against source
- `.planning/codebase/CONVENTIONS.md` — naming and variable conventions confirmed
- Zsh documentation: `typeset -U path` is the canonical zsh PATH dedup idiom (built-in, no external source needed)

### Secondary (MEDIUM confidence)
- `.planning/ROADMAP.md` — success criteria for DEBT-01 through DEBT-04 used as requirements cross-check
- `.planning/REQUIREMENTS.md` — DEBT-03 description cross-checked against actual grep results

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all techniques are zsh built-ins
- Architecture: HIGH — codebase fully read; all OSTYPE locations enumerated; PATH source confirmed
- Pitfalls: HIGH — deps.zsh ordering issue confirmed by reading .zshrc sourcing order; typeset-U casing confirmed by zsh docs
- DEBT-03 scope: HIGH — confirmed by grep that `~/.dotfiles/zsh` does not appear in any `.zsh` config file

**Research date:** 2026-03-14
**Valid until:** 2026-06-14 (stable zsh built-ins; no external dependencies to go stale)
