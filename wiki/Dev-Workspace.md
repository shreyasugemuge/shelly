# Dev Workspace (devterm)

`devterm` creates iTerm2 tabs with Claude Code panes for AI-assisted development.

> **Requires** iTerm2 with Python API enabled: Preferences > General > Magic > Enable Python API

## Standard Mode

Pick 1-3 projects from your code folder. Each project gets a column with Claude Code (80%) on top and a terminal (20%) on the bottom.

```
┌──────────────────┬──────────────────┬──────────────────┐
│ claude :: proj1  │ claude :: proj2  │ claude :: proj3  │
│                  │                  │                  │
│  Claude Code     │  Claude Code     │  Claude Code     │
│  (80%)           │  (80%)           │  (80%)           │
│                  │                  │                  │
├──────────────────┼──────────────────┼──────────────────┤
│ terminal :: proj1│ terminal :: proj2│ terminal :: proj3│
│  (20%)           │  (20%)           │  (20%)           │
└──────────────────┴──────────────────┴──────────────────┘
```

### Commands

| Command          | Description                               |
|------------------|-------------------------------------------|
| `devterm`        | Pick projects and launch                  |
| `devterm kill`   | Close the devterm tab                     |
| `devterm status` | Check tab state                           |
| `devterm help`   | Quick reference                           |

### Yolo Mode

Append `y` to a project number to launch Claude Code with `--dangerously-skip-permissions`:

```
Enter projects: 1y 3
```

This opens project 1 in skip-permissions mode and project 3 normally. Yolo panes show `⚡ claude :: project` in the title.

## Split Mode

`devterm -s` opens a single project with 1-8 Claude Code panes in an optimal grid layout. Every pane runs `claude --dangerously-skip-permissions`.

### Grid Layouts

| Panes | Layout     | Description          |
|-------|------------|----------------------|
| 1     | full       | Single pane          |
| 2     | [2]        | Side by side         |
| 3     | [3]        | Three columns        |
| 4     | [2x2]      | 2 rows, 2 columns   |
| 5     | [2+2+1]    | 2+2+1 rows          |
| 6     | [3x3]      | 2 rows, 3 columns   |
| 7     | [3+3+1]    | 3+3+1 rows          |
| 8     | [4x4]      | 2 rows, 4 columns   |

### Commands

| Command              | Description                                    |
|----------------------|------------------------------------------------|
| `devterm -s`         | Pick a project and launch split grid           |
| `devterm -s -c`      | Use current directory (skip project picker)     |
| `devterm -s kill`    | Close the split tab                            |
| `devterm -s status`  | Check split tab state                          |
| `devterm -s help`    | Show split mode help                           |

### Current Directory Mode

`devterm -s -c` skips the project picker entirely — it uses whatever directory you're in and only asks for the pane count. Useful when you're already `cd`'d into a project.

## Configuration

| Variable        | Default     | Description                |
|-----------------|-------------|----------------------------|
| `DEVTMUX_DIR`   | `~/code`    | Directory to scan for projects |

Set it in `~/.zshrc.local`:

```bash
export DEVTMUX_DIR="$HOME/projects"
```

## How It Works

Both modes use a three-phase build:
1. **Create splits** — build the pane layout using `it2api` commands
2. **Resize/equalize** — use the iTerm2 Python API to set correct proportions
3. **Launch** — clear scrollback, set pane titles, lock titles, start Claude Code

Session state is tracked in `~/.cache/zsh/`:
- `devterm.session_id` — standard mode
- `devterm-split.session_id` — split mode

Standard devterm and split mode have separate state and can coexist.

## Legacy

`devtmux` still works as a deprecation shim that redirects to `devterm`.
