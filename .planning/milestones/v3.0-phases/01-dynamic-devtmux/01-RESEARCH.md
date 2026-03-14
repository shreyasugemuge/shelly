# Phase 1: Dynamic devtmux - Research

**Researched:** 2026-03-14
**Domain:** zsh function authoring, tmux session/pane management, fzf interactive selection
**Confidence:** HIGH — all patterns verified against existing codebase, no external dependency on unverified libraries

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Project Picker UX**
- Show git repos only (directories containing `.git`) — filter out non-repo folders
- Display project name + current git branch, e.g. `vipms (main)`
- Use fzf multi-select when available: Tab to mark items, Enter to confirm
- If more than 3 selected, take first 3 and print warning: "Max 3 projects — using first 3"
- Fallback to numbered list when fzf is not installed — user types numbers separated by spaces

**Session Handling**
- When "dev" session already exists: prompt user "Reattach or start fresh?"
- If already inside tmux (e.g. sysmon): use `tmux switch-client` to move to dev session — no nesting
- Full subcommand set mirroring sysmon: `devtmux kill`, `devtmux status`, `devtmux help`
- `devtmux status` shows: which projects are open, session state, fzf availability

**Code Folder Discovery**
- Default to `~/code` — check if directory exists
- If `~/code` doesn't exist: prompt user for code folder path
- Persist chosen path by appending `export DEVTMUX_DIR="/path/to/code"` to `~/.zshrc.local`
- On subsequent runs: check `$DEVTMUX_DIR` first, fall back to `~/code`

**Layout & Scaling**
- 85/15 vertical split per column: Claude Code pane on top (~85%), terminal on bottom (~15%)
- Scale columns to selection count: 1 project = full width, 2 = 50/50, 3 = 33/33/33
- Use `select-layout even-horizontal` for equal column widths (matches current alias)
- Status bar: distinct from sysmon — magenta/purple accent (sysmon uses amber)
- Status bar shows session label "devtmux" + project names
- Mouse enabled for pane switching/resizing

### Claude's Discretion
- Exact fzf flags and configuration
- Numbered list prompt formatting
- Error message wording
- Helper function naming (`_devtmux_*` prefix pattern)
- How to handle edge case: code folder exists but has no git repos

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DEV-01 | `devtmux` command launches interactive project selection workflow | zsh function with case/esac entry point; fzf picker or numbered fallback |
| DEV-02 | Auto-detects `~/code` as default code folder, prompts if not found | `[[ -d "$dir" ]]` guard + `vared` or `read` prompt; persist to `~/.zshrc.local` |
| DEV-03 | User can select 1-3 projects from code folder subdirectories | `find`/glob to enumerate `.git` dirs; enforce max-3 with array slice |
| DEV-04 | Project picker uses fzf when available, falls back to numbered list | `command -v fzf` guard; `fzf --multi --header` path vs. numbered `read` prompt |
| DEV-05 | Opens tmux session "dev" with one column per selected project | `tmux new-session -d -s dev`; `split-window -h` loop; `select-layout even-horizontal` |
| DEV-06 | Each column has Claude Code pane (~85% top) and terminal pane (~15% bottom) | `split-window -v -p 15` per column after all columns exist |
| DEV-07 | Claude Code auto-launches in each project's directory | `send-keys "clear && claude" C-m` into each top pane |
| DEV-08 | Reattaches to existing "dev" session, or offers to kill and recreate | `tmux has-session -t dev`; prompt with `read` choice; `switch-client` if inside tmux |
| DEV-09 | Works on macOS and Linux | No macOS-only tmux flags used; git branch detection works cross-platform |
| DEV-10 | `devtmux kill` tears down the dev session | `kill` case in case/esac matching sysmon pattern |
</phase_requirements>

---

## Summary

This phase replaces the hardcoded `devtmux` alias (lines 47-60 of `config/aliases.zsh`) with a full zsh function in `config/functions.zsh`. The function dynamically discovers git repos under a configurable code folder, presents an interactive picker (fzf or numbered fallback), and builds a tmux session with one column per selected project — each column split 85/15 between a Claude Code pane and a bare terminal.

The project already has a complete reference implementation in `config/monitor.zsh` (`sysmon`). The architecture, helper function conventions, subcommand pattern, color scheme, and tmux management idioms are all proven and directly reusable. This phase is predominantly a new function that follows the established pattern, with the added complexity of dynamic pane construction and an interactive picker.

The only new technical territory (relative to sysmon) is: (1) fzf multi-select integration with a fallback, (2) dynamic tmux layout construction based on a variable number of projects (1-3), and (3) persisting user configuration to `~/.zshrc.local`.

**Primary recommendation:** Model the function directly on `sysmon` in `monitor.zsh`. Reuse the same color codes, `_` helper prefix, case/esac entry point, and `tmux has-session` reattach logic. The dynamic layout is the hardest part — build columns with a loop and use `select-layout even-horizontal` at the end (proven in the current alias).

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| zsh functions | — | Host `devtmux` logic | Already used for all helpers in functions.zsh |
| tmux | project dep | Session, pane, layout management | Already required by sysmon; in project's deps |
| fzf | optional | Interactive multi-select project picker | Widely installed by homebrew users; graceful fallback required |
| git | system | Branch detection per repo (`git -C dir branch --show-current`) | Already used throughout project aliases |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `~/.zshrc.local` | — | Persist `DEVTMUX_DIR` across sessions | Already sourced by `.zshrc` line 66; not git-tracked |
| `vared` / `read` | zsh built-in | Prompt user for code folder path | `vared` is zsh-native and supports editing; `read -r` works too |
| `select-layout even-horizontal` | tmux built-in | Equal column widths | Already used in the hardcoded devtmux alias |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `fzf --multi` | `select` built-in (zsh) | `select` is always available but single-item only and poor UX; fzf is far better when present |
| `git -C dir branch --show-current` | `git -C dir rev-parse --abbrev-ref HEAD` | `--show-current` cleaner but requires git 2.22+; `rev-parse` works on all versions — use `rev-parse` for broader compatibility |
| Inline tmux commands | `tmux send-keys` | Both work; the current alias uses `send-keys` for running commands in panes — keep that approach |

**Installation:** No new deps — tmux and fzf are already in the project's optional dep detection in `deps.zsh`.

---

## Architecture Patterns

### Recommended Project Structure

The new function lives entirely in `config/functions.zsh`. No new files needed.

```
config/
├── aliases.zsh       # Remove lines 47-60 (hardcoded devtmux alias)
├── functions.zsh     # ADD: _DEVTMUX_SESSION, _devtmux_* helpers, devtmux() entry point
├── monitor.zsh       # Reference: sysmon architecture (do not modify)
└── ...
```

### Pattern 1: Session Constant + Helper Prefix (from sysmon)

**What:** Define session name as a module-level constant; all private helpers use `_devtmux_` prefix.
**When to use:** Always — matches established convention.

```zsh
# Source: config/monitor.zsh lines 27-28 (sysmon reference)
_DEVTMUX_SESSION="dev"

_devtmux_pick_projects() { ... }
_devtmux_build_session() { ... }
_devtmux_status() { ... }

function devtmux() {
    case "${1:-}" in
        kill|stop) ... ;;
        status|info) _devtmux_status ;;
        help|-h|--help) ... ;;
        *) _devtmux_launch ;;
    esac
}
```

### Pattern 2: tmux Inside-Check Before attach/switch

**What:** Detect if already inside a tmux session. If yes, use `switch-client`; if no, use `attach-session`. This prevents nesting.
**When to use:** Every time the function would normally call `tmux attach-session`.

```zsh
# Source: tmux man page / standard pattern
if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$_DEVTMUX_SESSION"
else
    tmux attach-session -t "$_DEVTMUX_SESSION"
fi
```

### Pattern 3: fzf Multi-Select with Fallback

**What:** Use `fzf --multi` when available; fall back to a numbered list prompt.
**When to use:** Project picker (DEV-04).

```zsh
_devtmux_pick_projects() {
    local code_dir="$1"
    local repos=()

    # Enumerate git repos, collect "name (branch)" display strings
    for d in "$code_dir"/*/; do
        [[ -d "$d/.git" ]] || continue
        local name="${d:t}"    # basename via zsh :t modifier
        local branch
        branch="$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
        repos+=("${name} (${branch})")
    done

    if (( ${#repos[@]} == 0 )); then
        echo -e "\033[0;31m✗\033[0m No git repos found in $code_dir"
        return 1
    fi

    local selected=()
    if command -v fzf &>/dev/null; then
        # fzf multi-select: Tab marks, Enter confirms
        local raw
        raw="$(printf '%s\n' "${repos[@]}" | fzf --multi --prompt='Select projects (Tab=mark, Enter=confirm): ' --header='devtmux — select 1-3 projects')"
        [[ -z "$raw" ]] && return 1   # user cancelled
        while IFS= read -r line; do
            selected+=("$line")
        done <<< "$raw"
    else
        # Numbered fallback
        echo ""
        local i=1
        for r in "${repos[@]}"; do
            echo "  $i) $r"
            (( i++ ))
        done
        echo ""
        local choices
        read -r "choices?Select projects (1-3, space-separated): "
        for n in ${(z)choices}; do
            [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#repos[@]} )) && selected+=("${repos[$n]}")
        done
    fi

    # Enforce max 3
    if (( ${#selected[@]} > 3 )); then
        echo -e "\033[0;33m·\033[0m Max 3 projects — using first 3"
        selected=("${selected[@]:0:3}")
    fi

    if (( ${#selected[@]} == 0 )); then
        echo -e "\033[0;31m✗\033[0m No projects selected"
        return 1
    fi

    # Return names only (strip branch suffix " (branch)")
    for s in "${selected[@]}"; do
        echo "${s% (*}"
    done
}
```

### Pattern 4: Dynamic Column Layout

**What:** Build columns with a loop, then apply `select-layout even-horizontal`, then add bottom terminal panes.
**When to use:** `_devtmux_build_session()` implementation.

```zsh
_devtmux_build_session() {
    local projects=("$@")   # array of project names
    local code_dir="${DEVTMUX_DIR:-$HOME/code}"
    local count=${#projects[@]}

    # Create session with first project
    tmux new-session -d -s "$_DEVTMUX_SESSION" \
        -c "$code_dir/${projects[1]}" \
        -x "$(tput cols)" -y "$(tput lines)"

    # Add remaining columns
    for (( i=2; i<=count; i++ )); do
        tmux split-window -h -t "$_DEVTMUX_SESSION" \
            -c "$code_dir/${projects[$i]}"
    done

    # Equalize column widths
    tmux select-layout -t "$_DEVTMUX_SESSION" even-horizontal

    # Add ~15% terminal pane at bottom of each column
    # After even-horizontal, panes are 0..(count-1); split each
    for (( i=0; i<count; i++ )); do
        tmux split-window -v -t "$_DEVTMUX_SESSION:0.$i" -p 15 \
            -c "$code_dir/${projects[$((i+1))]}"
    done

    # Launch Claude Code in each top pane
    # After splits: top panes are 0, 2, 4 for 3 projects; 0, 2 for 2; 0 for 1
    for (( i=0; i<count; i++ )); do
        local top_pane=$(( i * 2 ))
        tmux send-keys -t "$_DEVTMUX_SESSION:0.$top_pane" "clear && claude" C-m
    done

    # Clear bottom terminal panes
    for (( i=0; i<count; i++ )); do
        local bot_pane=$(( i * 2 + 1 ))
        tmux send-keys -t "$_DEVTMUX_SESSION:0.$bot_pane" "clear" C-m
    done

    # Status bar — magenta/purple accent (distinct from sysmon amber)
    tmux set-option -t "$_DEVTMUX_SESSION" status on
    tmux set-option -t "$_DEVTMUX_SESSION" status-style 'bg=colour235,fg=colour248'
    tmux set-option -t "$_DEVTMUX_SESSION" status-left " #[fg=colour135,bold]devtmux#[fg=colour248] │ #[fg=colour183]${(j:, :)projects}#[fg=colour248] "
    tmux set-option -t "$_DEVTMUX_SESSION" status-left-length 60
    tmux set-option -t "$_DEVTMUX_SESSION" status-right '#[fg=colour245]Ctrl-b d detach '
    tmux set-option -t "$_DEVTMUX_SESSION" pane-border-style 'fg=colour237'
    tmux set-option -t "$_DEVTMUX_SESSION" pane-active-border-style 'fg=colour135'
    tmux set-option -t "$_DEVTMUX_SESSION" mouse on

    # Focus top-left pane
    tmux select-pane -t "$_DEVTMUX_SESSION:0.0"
}
```

### Pattern 5: Pane Index After Mixed Splits (CRITICAL — Most Likely Bug Source)

**What:** After `select-layout even-horizontal` on N columns, adding vertical splits changes pane indices. The relationship is predictable only if splits are done in order.
**When to use:** Any time pane indices must be referenced after mixed split sequences.

The current hardcoded alias uses an explicit sequential split approach with explicit pane indices (0, 1, 2, 3, 4, 5). The dynamic version must track pane indices carefully. The safest approach is:

1. Create all top panes first (horizontal splits only)
2. Apply `select-layout even-horizontal`
3. Add vertical splits top-to-bottom, left-to-right
4. After the split sequence, pane order is deterministic: for N columns, top panes are indices `0, 2, 4, ...` and bottom panes are `1, 3, 5, ...`

This matches the hardcoded alias behavior exactly (panes 0/1, 2/3, 4/5 for 3 projects).

### Anti-Patterns to Avoid

- **Do not nest tmux:** Never call `tmux attach-session` when `$TMUX` is set. Use `switch-client` instead.
- **Do not `select-layout` between vertical splits:** `select-layout even-horizontal` resets pane geometry. Call it once after all horizontal splits, before any vertical splits.
- **Do not assume pane indices without tracking:** After mixed splits, manually count or use a loop based on the predictable pattern above.
- **Do not store project list in a temp file:** Use function-local arrays and pass them as arguments.
- **Do not source `~/.zshrc.local` directly to read DEVTMUX_DIR:** The variable is already exported when zsh sources `.zshrc.local` — just check `$DEVTMUX_DIR` at runtime.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package manager detection | Custom detection logic | Copy `_sysmon_pkg_install()` pattern verbatim | Already tested; handles brew/apt/dnf/pacman — though fzf is optional so auto-install may not be needed |
| Equal column widths | Calculate `split-window -p N` percentages | `select-layout even-horizontal` | tmux built-in handles arbitrary N; percentage math is error-prone |
| Git branch reading | Parse `git status` output | `git -C "$dir" rev-parse --abbrev-ref HEAD` | Single-purpose, clean output, cross-platform |
| Color escape codes | Define new color variables | Reuse `\033[0;32m` (green), `\033[0;31m` (red), `\033[0;90m` (dim gray) from sysmon | Consistency with existing UI |

**Key insight:** Everything needed for this feature exists either as a tmux built-in (`select-layout`, `split-window`, `send-keys`) or is already implemented in the codebase (`monitor.zsh`). The function is assembly work, not invention.

---

## Common Pitfalls

### Pitfall 1: Pane Index Drift After Vertical Splits
**What goes wrong:** After adding vertical splits to columns, referencing panes by hardcoded index (e.g. `-t 0.2`) fails because each `split-window -v` increments all subsequent pane indices.
**Why it happens:** tmux pane indices are sequential and shift when new panes are inserted before them.
**How to avoid:** Add all horizontal splits first, then apply `select-layout even-horizontal`, then add vertical splits left-to-right. After this sequence, the pattern is deterministic: column N has top pane at index `N*2` and bottom pane at `N*2+1`.
**Warning signs:** Claude Code launches in wrong directory, or `send-keys` sends to wrong pane.

### Pitfall 2: fzf Output Includes Branch Suffix
**What goes wrong:** Picker returns `"projectname (main)"` but the code tries to use it as a directory name (`~/code/projectname (main)` does not exist).
**Why it happens:** Display strings include branch info for UX, but directory names are just the repo folder name.
**How to avoid:** Strip the branch suffix before using as a path: `${selection% (*}`.
**Warning signs:** `tmux new-session` fails with bad working directory; split-window silently opens in `$HOME`.

### Pitfall 3: select-layout Resets After Additional Splits
**What goes wrong:** `select-layout even-horizontal` is called after adding a vertical split, which reverts the layout.
**Why it happens:** `select-layout` recalculates all pane geometry from scratch.
**How to avoid:** Call `select-layout even-horizontal` ONCE, only after ALL horizontal splits are done and BEFORE any vertical splits.
**Warning signs:** Bottom terminal pane appears as a full-width strip instead of per-column.

### Pitfall 4: $TMUX Check for Nesting Prevention
**What goes wrong:** Calling `tmux attach-session` when already inside tmux prints an error or creates a nested session depending on version.
**Why it happens:** `attach-session` in a tmux pane is not valid without `-d` flag and typically fails.
**How to avoid:** Check `[[ -n "$TMUX" ]]` before attaching. Use `switch-client` when inside tmux.
**Warning signs:** Error "sessions should be nested with care, unset $TMUX to force".

### Pitfall 5: zshrc.local Append Creates Duplicate Entries
**What goes wrong:** Running `devtmux` a second time without an existing `$DEVTMUX_DIR` appends a second `export DEVTMUX_DIR=...` line to `~/.zshrc.local`.
**Why it happens:** The append logic fires whenever the env var is unset at function call time — but it IS set in the current session after the first write, so this only triggers once per session. However, across shells or after a fresh login before sourcing `.zshrc.local`, it could trigger again.
**How to avoid:** Before appending, grep `~/.zshrc.local` for an existing `DEVTMUX_DIR` line and skip if found. Or use a sed-replace pattern instead of append.
**Warning signs:** `~/.zshrc.local` accumulates multiple `export DEVTMUX_DIR=` lines.

### Pitfall 6: fzf Not Installed, Command Returns Error
**What goes wrong:** `command -v fzf` check passes but fzf is broken or not in PATH inside a non-interactive context.
**Why it happens:** PATH differences between interactive and function contexts are rare in zsh but possible.
**How to avoid:** The `command -v fzf` guard is sufficient for this use case since devtmux only runs interactively. Standard practice.

### Pitfall 7: Code Folder Has No Git Repos
**What goes wrong:** `~/code` exists but contains no `.git` subdirectories — picker is empty.
**Why it happens:** Fresh install, different folder structure, or user's code folder contains non-git projects.
**How to avoid:** After building the `repos` array, check `(( ${#repos[@]} == 0 ))` and print an actionable error: `"No git repos found in $code_dir. Set DEVTMUX_DIR to a different folder."` Then return 1.

---

## Code Examples

Verified patterns from existing codebase:

### Existing Hardcoded Alias (lines 47-60 of config/aliases.zsh) — to be replaced
```zsh
# Source: config/aliases.zsh:47-60
alias devtmux='tmux new-session -s dev -c ~/code/vipms -n dev \; \
  split-window -h -c ~/code/vipl-email-agent \; \
  split-window -h -c ~/code/erpnext \; \
  select-layout even-horizontal \; \
  select-pane -t 0 \; split-window -v -p 20 -c ~/code/vipms \; \
  select-pane -t 2 \; split-window -v -p 20 -c ~/code/vipl-email-agent \; \
  select-pane -t 4 \; split-window -v -p 20 -c ~/code/erpnext \; \
  send-keys -t 1 "clear" C-m \; \
  send-keys -t 3 "clear" C-m \; \
  send-keys -t 5 "clear" C-m \; \
  send-keys -t 0 "clear && claude" C-m \; \
  send-keys -t 2 "clear && claude" C-m \; \
  send-keys -t 4 "clear && claude" C-m \; \
  select-pane -t 0'
```

Key observations from this alias:
- Session created with `-c` (working dir) and `-n` (window name)
- Horizontal splits added before `select-layout even-horizontal`
- `select-pane -t N` targets a specific pane before the vertical split — the new pane inherits that pane's context
- After 3 horizontal splits + `select-layout`, pane 0 is leftmost column top
- `split-window -v -p 20` = bottom pane gets 20% = top gets 80% (close to the desired 85/15)
- Bottom terminal panes: 1, 3, 5 — top Claude panes: 0, 2, 4 (exactly N*2+1 and N*2)

### sysmon Entry Point Pattern (config/monitor.zsh:286-328)
```zsh
# Source: config/monitor.zsh:286-328
function sysmon() {
    case "${1:-}" in
        kill|stop)
            if tmux has-session -t "$_SYSMON_SESSION" 2>/dev/null; then
                tmux kill-session -t "$_SYSMON_SESSION"
                echo -e "\033[0;32m✓\033[0m sysmon session terminated"
            else
                echo -e "\033[0;90m·\033[0m No sysmon session running"
            fi
            ;;
        status|info) _sysmon_status ;;
        help|-h|--help) ... ;;
        *)
            _sysmon_ensure_deps
            if tmux has-session -t "$_SYSMON_SESSION" 2>/dev/null; then
                echo -e "\033[0;90m·\033[0m Reattaching to existing sysmon session…"
                tmux attach-session -t "$_SYSMON_SESSION"
            else
                _sysmon_launch
            fi
            ;;
    esac
}
```

### Session Existence + Reattach/Recreate Prompt
```zsh
# Pattern for DEV-08 (reattach or start fresh)
if tmux has-session -t "$_DEVTMUX_SESSION" 2>/dev/null; then
    local choice
    read -r "choice?devtmux session exists. [r]eattach or [k]ill and start fresh? "
    case "$choice" in
        k|K|kill)
            tmux kill-session -t "$_DEVTMUX_SESSION"
            _devtmux_launch
            ;;
        *)
            if [[ -n "$TMUX" ]]; then
                tmux switch-client -t "$_DEVTMUX_SESSION"
            else
                tmux attach-session -t "$_DEVTMUX_SESSION"
            fi
            ;;
    esac
else
    _devtmux_launch
fi
```

### Persisting DEVTMUX_DIR to ~/.zshrc.local
```zsh
# Guard against duplicate entries before appending
_devtmux_persist_dir() {
    local dir="$1"
    local local_rc="$HOME/.zshrc.local"
    if [[ -f "$local_rc" ]] && grep -q 'DEVTMUX_DIR' "$local_rc"; then
        return 0  # already set, don't duplicate
    fi
    echo "export DEVTMUX_DIR=\"${dir}\"" >> "$local_rc"
    echo -e "\033[0;90m·\033[0m Saved DEVTMUX_DIR to ~/.zshrc.local"
}
```

### Discover Code Folder (DEV-02)
```zsh
_devtmux_get_code_dir() {
    local dir="${DEVTMUX_DIR:-$HOME/code}"
    if [[ ! -d "$dir" ]]; then
        echo -e "\033[0;33m·\033[0m Code folder not found: $dir"
        local input
        read -r "input?Enter path to your code folder: "
        dir="${input/#\~/$HOME}"   # expand leading ~
        if [[ ! -d "$dir" ]]; then
            echo -e "\033[0;31m✗\033[0m Directory does not exist: $dir"
            return 1
        fi
        _devtmux_persist_dir "$dir"
        export DEVTMUX_DIR="$dir"
    fi
    echo "$dir"
}
```

### tmux Status Bar Colors (magenta/purple — distinct from sysmon amber)
```zsh
# sysmon uses: colour214 (amber) for label
# devtmux uses: colour135 (magenta) for label, colour183 (light purple) for project names
tmux set-option -t "$_DEVTMUX_SESSION" status-left " #[fg=colour135,bold]devtmux#[fg=colour248] │ #[fg=colour183]${projects_display}#[fg=colour248] "
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded alias with 3 fixed projects | Dynamic function with 1-3 selectable projects | Phase 1 (this work) | Any code folder works; not just vipms/vipl-email-agent/erpnext |
| `select-pane -t N` before split (alias style) | Loop-based split with predictable N*2/N*2+1 index pattern | Phase 1 | Scales to 1, 2, or 3 projects cleanly |

**Deprecated/outdated after this phase:**
- Lines 47-60 of `config/aliases.zsh` — the hardcoded `devtmux` alias is removed when the function is added

---

## Open Questions

1. **fzf `--multi` prompt display on narrow terminals**
   - What we know: fzf respects terminal width; `--header` text wraps gracefully
   - What's unclear: Whether the header string is too long on very narrow terminals (80 cols)
   - Recommendation: Keep header short ("devtmux — pick 1-3 projects") and test at 80 cols

2. **`tput cols` / `tput lines` in non-interactive context**
   - What we know: `tmux new-session -x "$(tput cols)" -y "$(tput lines)"` is used successfully in sysmon (monitor.zsh:203)
   - What's unclear: Whether this behaves consistently when `devtmux` is called from within an existing tmux pane
   - Recommendation: The sysmon pattern is proven — copy it verbatim. If terminal size is wrong, it's an edge case not worth over-engineering.

3. **zsh array indexing: 1-based vs 0-based**
   - What we know: zsh arrays are 1-based by default (`${arr[1]}` is first element), unlike bash (0-based)
   - What's unclear: The pane loop in Pattern 4 uses bash-style `(( i=0; i<count; i++ ))` with `${projects[$((i+1))]}` inside — this needs careful verification
   - Recommendation: In zsh arithmetic loops, use `(( i=1; i<=count; i++ ))` with `${projects[$i]}` for the array and keep the pane index math as `$(( (i-1)*2 ))`.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual — shell configs are tested by `exec zsh` (per REQUIREMENTS.md out-of-scope) |
| Config file | None |
| Quick run command | `exec zsh && devtmux help` |
| Full suite command | `exec zsh && devtmux status && devtmux help && devtmux kill` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEV-01 | `devtmux` launches picker workflow | manual | `exec zsh && devtmux` | ❌ Wave 0 |
| DEV-02 | Auto-detects `~/code`, prompts if missing | manual | Set `DEVTMUX_DIR=""` then run `devtmux` | ❌ Wave 0 |
| DEV-03 | 1-3 project selection enforced | manual | Select 4 items in fzf picker | ❌ Wave 0 |
| DEV-04 | fzf picker + numbered fallback | manual | Rename fzf, confirm fallback activates | ❌ Wave 0 |
| DEV-05 | "dev" session opens with correct columns | manual | `tmux list-panes -t dev` after launch | ❌ Wave 0 |
| DEV-06 | 85/15 vertical split per column | manual | `tmux display-panes -t dev` inspect heights | ❌ Wave 0 |
| DEV-07 | Claude Code auto-launches in each project dir | manual | Inspect pane content after session starts | ❌ Wave 0 |
| DEV-08 | Reattach/recreate prompt for existing session | manual | Launch `devtmux` twice; verify prompt appears | ❌ Wave 0 |
| DEV-09 | macOS + Linux compatible | manual | Test on both platforms (or verify no OS-specific code) | ❌ Wave 0 |
| DEV-10 | `devtmux kill` tears down session | smoke | `devtmux kill && tmux ls 2>&1 \| grep -v dev` | ❌ Wave 0 |

**Note:** Per REQUIREMENTS.md, automated test framework is out of scope for this project. All validation is manual via `exec zsh` reload and functional testing.

### Sampling Rate
- **Per task commit:** `exec zsh && devtmux help` (confirms function loads without error)
- **Per wave merge:** Full manual checklist against all DEV-0x requirements
- **Phase gate:** All requirements manually verified before `/gsd:verify-work`

### Wave 0 Gaps
- No automated test files to create — validation is manual per project scope
- The only prerequisite is that `exec zsh` succeeds (no parse errors in functions.zsh)

---

## Sources

### Primary (HIGH confidence)
- `config/monitor.zsh` (project codebase) — sysmon architecture, tmux patterns, color codes, subcommand pattern
- `config/aliases.zsh:47-60` (project codebase) — existing devtmux alias, confirmed pane index behavior
- `config/functions.zsh` (project codebase) — function file structure and conventions
- `.zshrc` (project codebase) — sourcing order, `~/.zshrc.local` integration
- `.planning/phases/01-dynamic-devtmux/01-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- tmux `split-window`, `select-layout`, `send-keys`, `has-session`, `switch-client` — standard tmux commands, behavior verified against existing alias
- fzf `--multi` flag — standard fzf feature; `command -v fzf` guard is standard pattern

### Tertiary (LOW confidence)
- Pane index formula (N*2 top, N*2+1 bottom) after mixed splits — inferred from alias behavior; needs validation during implementation. The alias targets panes 0,2,4 for top and 1,3,5 for bottom, which matches this formula for 3 projects.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools already in project, patterns verified against codebase
- Architecture: HIGH — directly modeled on sysmon (working reference implementation)
- Pitfalls: HIGH — pane index pitfall inferred from hardcoded alias analysis; duplication guard from general shell knowledge

**Research date:** 2026-03-14
**Valid until:** Stable patterns — valid until tmux major version change (unlikely within months)
