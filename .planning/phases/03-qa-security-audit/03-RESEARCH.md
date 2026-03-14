# Phase 3: QA & Security Audit - Research

**Researched:** 2026-03-14
**Domain:** Shell script static analysis (shellcheck), input validation, security hardening
**Confidence:** HIGH

## Summary

Phase 3 hardens the shelly codebase through shellcheck static analysis, input validation, PATH hardening, and a tracked-file secrets audit. All config files are in `config/` and the entry point is `.zshrc`. Phases 1 and 2 are complete — devtmux and the platform-detection refactor are both in place.

Shellcheck does not officially support zsh. The practical approach is to run it with `--shell=bash`, which catches ~95% of real issues while generating predictable false positives for zsh-specific syntax (array indexing, `typeset -U`, `(( ))` arithmetic, `${var:h}` path modifiers). These false positives should be suppressed with inline `# shellcheck disable=SCXXXX` directives accompanied by a comment explaining why, or globally via a `.shellcheckrc` file at the repo root.

A pre-read of all eight config files reveals a small, bounded set of real issues: one SC2155 violation (`export GPG_TTY=$(tty)` and `local brew_share="$(brew --prefix ...)"`), shellcheck will flag `if $IS_MACOS` boolean tests, and the `locip` alias contains complex nested quoting. Input validation gaps in `portfind` (accepts arbitrary `:PORT` argument) and `mkcd` (no path sanitization) are the primary QA-02 targets. PATH construction is already clean (`typeset -U path` from Phase 2 handles deduplication). The secrets/paths audit finds no credentials — all `$HOME` references are via the variable, not hardcoded.

**Primary recommendation:** Install shellcheck via brew, run it per-file with `--shell=bash`, fix real issues, document zsh-specific false positives in `.shellcheckrc`, and add a protective guard comment to `plugins.zsh` for the syntax-highlighting sourcing-order requirement.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| QA-01 | shellcheck passes on all config/*.zsh files (or documented exceptions) | shellcheck --shell=bash workflow identified; expected SC codes catalogued per file |
| QA-02 | Shell functions validate inputs (mkcd, extract, etc.) | mkcd has no path sanitization; portfind accepts arbitrary port argument; extract already validates file existence; pan and weather have adequate guards |
| QA-03 | PATH construction audited and hardened | typeset -U path already in place; NVM PATH prepend is the only dynamic addition; no hardcoded directories in PATH |
| QA-04 | Plugin sourcing order enforced with guard comment or check | plugins.zsh has informal comment but no explicit machine-readable guard; needs protective comment block |
| QA-05 | No secrets or machine-specific paths in tracked files | All $HOME refs use variable; no IPs, no credentials; "Author: Shreyas Ugemuge" is fine as attribution; no hardcoded /Users/... paths found |
</phase_requirements>

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| shellcheck | 0.11.0 (brew) | Static analysis for shell scripts | Industry standard; catches quoting bugs, SC codes map to fixes |
| bash/zsh built-ins | — | Input validation primitives (`[[ =~ ]]`, `(( ))`) | No external deps needed for validation |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `.shellcheckrc` | — | Per-repo shellcheck config (shell directive, disable list) | Suppress zsh-specific false positives globally |
| `# shellcheck disable=SC####` | — | Inline suppression with justification comment | For file-local suppressions where global is too broad |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| shellcheck --shell=bash | zsh-specific linter (e.g., zsh-lint) | No credible zsh-native linter exists; shellcheck+bash is the community standard |
| inline disable directives | Ignoring all shellcheck output | Inline directives are more targeted and self-documenting |

**Installation:**
```bash
brew install shellcheck
```

---

## Architecture Patterns

### Recommended shellcheck Workflow

```
shellcheck --shell=bash config/aliases.zsh
shellcheck --shell=bash config/deps.zsh
shellcheck --shell=bash config/environment.zsh
shellcheck --shell=bash config/functions.zsh
shellcheck --shell=bash config/monitor.zsh
shellcheck --shell=bash config/plugins.zsh
shellcheck --shell=bash config/prompt.zsh
shellcheck --shell=bash config/sysinfo.zsh
```

Or batch form (after shellcheck is installed):
```bash
shellcheck --shell=bash config/*.zsh
```

### Pattern 1: .shellcheckrc for zsh-specific global suppression

**What:** A `.shellcheckrc` at the repo root sets shell dialect and disables codes that are false positives in zsh.

**When to use:** For SC codes that fire on valid zsh syntax throughout multiple files.

**Example:**
```
# .shellcheckrc
shell=bash
# SC1071: "ShellCheck only supports sh/bash/dash/ksh" — files are .zsh, not bash
# SC2039: In POSIX sh, 'local' is undefined — not relevant; these are zsh files
disable=SC2039
```

Note: Keep `.shellcheckrc` minimal. Blanket disables hide real issues. Prefer per-line disables for any code-specific suppression.

### Pattern 2: Declare-then-assign (fix for SC2155)

**What:** SC2155 fires when `local`/`export` combines declaration with command substitution, masking the exit code of the subcommand.

**When to use:** Any `local var="$(cmd)"` or `export VAR=$(cmd)` pattern.

**Example — before (SC2155):**
```bash
# Source: shellcheck wiki SC2155
export GPG_TTY=$(tty)
local brew_share="$(brew --prefix 2>/dev/null)/share"
```

**Example — after (correct):**
```bash
GPG_TTY=$(tty)
export GPG_TTY

local brew_share
brew_share="$(brew --prefix 2>/dev/null)/share"
```

### Pattern 3: Input validation for shell functions

**What:** Validate type and range for numeric args; validate existence for path args; reject path traversal characters.

**When to use:** Any public function accepting user-supplied input.

**Example — portfind (QA-02 target):**
```zsh
function portfind() {
    if [[ -z "$1" ]]; then
        echo "Usage: portfind <port>"
        return 1
    fi
    # Reject non-numeric input
    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "portfind: port must be a number (got: $1)"
        return 1
    fi
    if (( $1 < 1 || $1 > 65535 )); then
        echo "portfind: port must be 1–65535 (got: $1)"
        return 1
    fi
    lsof -i :"$1"
}
```

**Example — mkcd (QA-02 target):**
```zsh
function mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    # mkcd is an interactive convenience function; deep path traversal is not
    # a realistic threat, but we can reject obviously suspicious input
    if [[ "$1" == *$'\0'* ]]; then
        echo "mkcd: null bytes not allowed in path"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}
```

### Pattern 4: Plugin sourcing order guard comment

**What:** A structured comment block (and optionally a runtime assertion) protecting the `zsh-syntax-highlighting` must-be-last requirement.

**When to use:** In `plugins.zsh`, immediately before the syntax-highlighting source line.

**Example:**
```zsh
# ── SOURCING ORDER GUARD ──
# zsh-syntax-highlighting MUST be the last plugin sourced.
# It wraps ZLE widgets; sourcing anything after it silently
# breaks those widgets. Do not add plugins below this line.
# See: https://github.com/zsh-users/zsh-syntax-highlighting#why-must-it-be-sourced-at-the-end
_sh_path="$(_find_plugin zsh-syntax-highlighting)"
if [[ -n "$_sh_path" ]]; then
    source "$_sh_path"
fi
```

### Anti-Patterns to Avoid

- **Blanket `# shellcheck disable` without justification:** Documents nothing; re-enables ignored bugs. Always add a reason comment.
- **`export VAR=$(cmd)` pattern:** Masks exit code of subcommand (SC2155). Declare then assign.
- **`if $BOOLEAN_VAR` in shellcheck context:** shellcheck (--shell=bash) will flag `if $IS_MACOS` as SC2166/SC2235 because it's not a standard bash idiom. The correct disable is `# shellcheck disable=SC2166` with a note that `IS_MACOS` is a boolean set by `.zshrc`.
- **Unquoted `$1` in case statements:** While zsh handles this, shellcheck flags it as SC2086. Use `"$1"` in case patterns where unambiguous.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shell static analysis | Custom lint script | shellcheck | Covers 400+ rule categories; actively maintained |
| Numeric range validation | Custom regex | `[[ "$1" =~ ^[0-9]+$ ]]` + `(( ))` | Native zsh; no subprocess needed |
| PATH deduplication | Custom loop | `typeset -U path` (already in place) | Zsh built-in; handles all edge cases |

**Key insight:** shellcheck + inline directives is the complete solution. No custom tooling needed.

---

## Common Pitfalls

### Pitfall 1: Running shellcheck on .zsh files without --shell=bash

**What goes wrong:** shellcheck immediately aborts with SC1071 "ShellCheck only supports sh/bash/dash/ksh scripts" because the shebang says `#!/bin/zsh`.

**Why it happens:** zsh is not an officially supported dialect.

**How to avoid:** Always pass `--shell=bash`. The `.shellcheckrc` approach also works by setting `shell=bash` globally so the flag is implicit.

**Warning signs:** Output reads "In [file] line 1: SC1071" only.

### Pitfall 2: Disabling too broadly

**What goes wrong:** Adding `disable=SC2086` globally in `.shellcheckrc` silences a rule that catches real quoting bugs elsewhere in the repo.

**Why it happens:** One zsh-specific pattern triggers the rule; the fix appears to be a global disable.

**How to avoid:** Use `# shellcheck disable=SC2086` inline, on the specific line, with a comment explaining the context. Reserve `.shellcheckrc` disables for dialect-level issues (SC1071, SC2039).

**Warning signs:** Useful warnings disappear from output but no inline directives explain why.

### Pitfall 3: SC2155 fix breaks intentional pattern

**What goes wrong:** Splitting `export GPG_TTY=$(tty)` into two lines changes behavior if `tty` fails — now `GPG_TTY` is exported as empty rather than unset.

**Why it happens:** SC2155 fix is mechanical without thinking about failure semantics.

**How to avoid:** When fixing SC2155, consider whether the command can fail and what the correct failure behavior is. For `GPG_TTY`, empty string is fine (GPG will just not work in non-TTY contexts). For `brew_share`, an empty prefix just means no brew plugins found — which is the correct fallback.

**Warning signs:** Functions that previously succeeded silently now emit different behavior after SC2155 fix.

### Pitfall 4: Touching the IS_MACOS boolean pattern

**What goes wrong:** shellcheck flags `if $IS_MACOS` throughout the codebase. The temptation is to change these to `if [[ "$IS_MACOS" == "true" ]]`. This changes the idiom used in 5 files and was established in Phase 2 as a deliberate design decision.

**Why it happens:** shellcheck (bash mode) doesn't understand that `IS_MACOS` is always `true` or `false` literals.

**How to avoid:** Use `# shellcheck disable=SC2166` (or the appropriate SC code) inline on each `if $IS_MACOS` line rather than changing the idiom. Add a brief comment explaining the pattern.

**Warning signs:** PR changes `if $IS_MACOS` → `if [[ "$IS_MACOS" == "true" ]]` across all files — that's unnecessary churn.

### Pitfall 5: "No secrets" audit conflating author attribution with PII

**What goes wrong:** The grep for sensitive data turns up "Author: Shreyas Ugemuge" in every file header and the GitHub URL. These are treated as a finding.

**Why it happens:** Broad pattern matching catches all names.

**How to avoid:** The QA-05 requirement is about machine-specific paths, credentials, and tokens — not author attribution or public GitHub URLs. "Shreyas Ugemuge" in comments and the repo URL are both intentional and fine. The audit should focus on: hardcoded `/Users/...` absolute paths, API keys, passwords, IP addresses, machine-specific hostnames.

**Warning signs:** Audit report lists comment attributions as issues.

---

## Code Examples

### Expected SC codes per file (pre-audit analysis)

**config/environment.zsh**
```zsh
# SC2155: export and assign separately
# BEFORE (flags SC2155):
export GPG_TTY=$(tty)

# AFTER:
GPG_TTY=$(tty)
export GPG_TTY
```

**config/deps.zsh**
```zsh
# SC2155: local and assign separately
# BEFORE (flags SC2155):
local brew_share="$(brew --prefix 2>/dev/null)/share"

# AFTER:
local brew_share
brew_share="$(brew --prefix 2>/dev/null)/share"
```

**config/functions.zsh, monitor.zsh, sysinfo.zsh, deps.zsh**
```zsh
# if $IS_MACOS pattern will flag SC2166 (or SC2235 depending on shellcheck version)
# Suppress inline with justification:
# shellcheck disable=SC2166  # IS_MACOS is a true/false boolean set in .zshrc
if $IS_MACOS; then
```

**config/aliases.zsh**
```zsh
# locip alias uses nested quoting that shellcheck may warn about (SC2016 or similar)
# Evaluate with shellcheck output in hand; may need inline disable
alias locip='echo "local: $(ipconfig getifaddr "$(route -n get default 2>/dev/null | awk "/interface:/{print \$2}")" 2>/dev/null || hostname -I 2>/dev/null | awk "{print \$1}")"'
```

### .shellcheckrc minimal setup
```
# Source: shellcheck docs - .shellcheckrc configuration
shell=bash
# These codes are zsh-specific idioms, not real bugs:
# SC2039: In POSIX sh, local is undefined — these are zsh files, not POSIX sh
disable=SC2039
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No linting at all | shellcheck with inline directives | Phase 3 | Catches quoting bugs before they reach users |
| No PATH deduplication | typeset -U path | Phase 2 (already done) | PATH cannot accumulate duplicates |
| No input validation in portfind | Numeric range check | Phase 3 | Prevents `:badarg` passed to lsof |

**Deprecated/outdated:**
- Running shellcheck without `--shell=bash` on .zsh files — always exits with SC1071

---

## Open Questions

1. **Exact SC codes shellcheck generates for `if $IS_MACOS`**
   - What we know: shellcheck in bash mode will warn about `if $VARIABLE` without `[[ ]]`
   - What's unclear: Whether it's SC2166, SC2235, or SC2166+SC2235 depending on shellcheck 0.11.0
   - Recommendation: Run `shellcheck --shell=bash config/functions.zsh` after installation and capture exact codes before writing inline directives

2. **Whether locip alias triggers actionable warnings**
   - What we know: The alias has complex nested quoting with escaped characters
   - What's unclear: shellcheck may refuse to analyze alias bodies or may produce false positives
   - Recommendation: Run shellcheck on aliases.zsh, evaluate output; if the alias warning is a false positive (shellcheck can't parse alias bodies reliably), document with a disable directive

3. **Whether `extract` needs more validation beyond file existence check**
   - What we know: `extract` already checks `[[ ! -f "$1" ]]`
   - What's unclear: Whether symlinks, special files, or relative paths with `../` sequences are a concern
   - Recommendation: The function is interactive-only; current validation is sufficient for QA-02. No change needed beyond confirming the existing check satisfies the requirement.

---

## Validation Architecture

> nyquist_validation key is absent from .planning/config.json — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification (exec zsh) — per REQUIREMENTS.md, automated test framework is out of scope |
| Config file | none |
| Quick run command | `exec zsh` (reload shell, check for errors) |
| Full suite command | `shellcheck --shell=bash config/*.zsh` + `exec zsh` + manual function tests |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QA-01 | shellcheck passes (or exceptions documented) | smoke | `shellcheck --shell=bash config/*.zsh` | ❌ Wave 0: shellcheck must be installed first |
| QA-02 | portfind rejects non-numeric/out-of-range ports | manual | `portfind abc; portfind 99999; portfind 80` | N/A — interactive function |
| QA-02 | mkcd handles empty input | manual | `mkcd; mkcd /tmp/test-mkcd-$$` | N/A — interactive function |
| QA-03 | PATH has no duplicates after shell reload | manual | `exec zsh; echo $PATH | tr ':' '\n' | sort | uniq -d` | N/A |
| QA-04 | plugins.zsh guard comment present | smoke | `grep -n 'SOURCING ORDER GUARD' config/plugins.zsh` | ❌ Wave 0: comment does not exist yet |
| QA-05 | No hardcoded /Users/ paths in tracked files | smoke | `git ls-files | xargs grep -l '/Users/' -- | grep -v CHANGELOG` | N/A — one-shot audit |

### Sampling Rate
- **Per task commit:** `exec zsh` (confirms no syntax errors introduced)
- **Per wave merge:** `shellcheck --shell=bash config/*.zsh && exec zsh`
- **Phase gate:** All shellcheck output resolved (fixed or documented) + manual function smoke tests pass

### Wave 0 Gaps
- [ ] `shellcheck` binary — install via `brew install shellcheck` before any QA-01 work
- [ ] `.shellcheckrc` at repo root — create with `shell=bash` before running batch audit

*(No test file gaps — validation is manual + shellcheck CLI, not a test framework)*

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection of all 8 config files — findings are concrete, file-and-line verified
- REQUIREMENTS.md — QA requirement IDs and success criteria read directly
- CONCERNS.md / CONVENTIONS.md — pre-existing knowledge of fragile areas (plugin order, ls alias, NVM lazy-load)

### Secondary (MEDIUM confidence)
- [shellcheck wiki SC2155](https://www.shellcheck.net/wiki/) — declare/assign separately rule
- [koalaman/shellcheck GitHub issue #809](https://github.com/koalaman/shellcheck/issues/809) — official confirmation that zsh is not supported; `--shell=bash` is the workaround
- [shellcheck man page — .shellcheckrc options](https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md) — configuration file format verified

### Tertiary (LOW confidence)
- WebSearch: zsh-specific SC code list — no authoritative 2025 list found; exact codes for `if $IS_MACOS` must be confirmed by running shellcheck post-install

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — shellcheck is the only tool; version from brew info confirmed
- Architecture: HIGH — all patterns derived from direct file inspection
- Pitfalls: HIGH — derived from existing CONCERNS.md + CLAUDE.md retrospectives + code read
- Exact SC codes for IS_MACOS pattern: LOW — must be confirmed post-install

**Research date:** 2026-03-14
**Valid until:** 2026-07-14 (shellcheck is stable; zsh support status unlikely to change)
