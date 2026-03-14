# Codebase Structure

## Directory Layout

```
shelly/
├── .zshrc                  # Entry point — sources all config/ modules
├── config/                 # Modular zsh configuration files
│   ├── aliases.zsh         # Shell aliases (ls, grep, navigation, git, etc.)
│   ├── deps.zsh            # Dependency checker (runs once/day)
│   ├── environment.zsh     # Environment variables, PATH, XDG dirs
│   ├── functions.zsh       # Utility shell functions (mkcd, extract, etc.)
│   ├── monitor.zsh         # sysmon tmux dashboard command
│   ├── plugins.zsh         # Plugin manager (zsh-autosuggestions, syntax-highlighting)
│   ├── prompt.zsh          # Custom prompt with git integration
│   └── sysinfo.zsh         # Startup splash screen (neofetch-style)
├── install.sh              # Setup script (symlinks, backup, --dry-run, --uninstall)
├── deploy.sh               # Release script (push, tag, GitHub release)
├── archive/                # Legacy bash configs (preserved, do not modify)
│   ├── .bashrc
│   ├── .bash_profile
│   └── .bash_aliases
├── VERSION                 # Semver version string
├── CHANGELOG.md            # Release history
├── CONTRIBUTING.md         # Development workflow docs
├── LICENSE
└── CLAUDE.md               # AI assistant context and project docs
```

## Key File Roles

### Entry Point
- `.zshrc` — Sources all `config/*.zsh` files. This is symlinked to `~/.config/zsh/.zshrc` by `install.sh`.

### Config Modules (config/)
Files are sourced in order by `.zshrc`. Each handles one concern:

| File | Purpose |
|------|---------|
| `environment.zsh` | PATH, EDITOR, XDG dirs, Homebrew, NVM lazy-load |
| `prompt.zsh` | PS1 with git branch/status, exit code face indicator |
| `aliases.zsh` | Shell shortcuts with BSD/GNU detection for `ls` |
| `functions.zsh` | Utility functions: `mkcd`, `extract`, `weather`, etc. |
| `plugins.zsh` | Plugin sourcing (syntax-highlighting MUST be last) |
| `deps.zsh` | Daily dependency check for required tools |
| `monitor.zsh` | `sysmon` command — tmux dashboard with btop/nvtop/macmon |
| `sysinfo.zsh` | Startup ASCII art + system stats display |

### Scripts
- `install.sh` — Idempotent installer. Creates XDG dirs, symlinks `.zshrc`, backs up existing config. Supports `--dry-run` and `--uninstall`.
- `deploy.sh` — One-command release: commits, tags, pushes, creates GitHub release.

### Archive
- `archive/` — Old bash configuration files. Read-only reference. Do not modify.

## Naming Conventions

### Files
- Config modules: `{concern}.zsh` in `config/` (lowercase, descriptive)
- Scripts: `{verb}.sh` at root (e.g., `install.sh`, `deploy.sh`)

### Functions
- Shell functions: `lowercase_snake_case` (e.g., `mkcd`, `extract`, `lazy_load_nvm`)
- Internal helpers: prefixed with `_` (e.g., `_git_branch`)

### Variables
- Environment variables: `UPPER_SNAKE_CASE` (e.g., `XDG_CONFIG_HOME`, `EDITOR`)
- Local variables: `lowercase` or `snake_case`
- Colors/formatting: descriptive names (e.g., `dim`, `reset`, `green`)

### Directories
- Lowercase, hyphenated for multi-word (e.g., `config/`, `archive/`)
- XDG-compliant paths: `~/.config/zsh/`, not `~/.zsh/`

## Where to Add New Code

| Adding... | Location |
|-----------|----------|
| New alias | `config/aliases.zsh` |
| New shell function | `config/functions.zsh` |
| New environment variable | `config/environment.zsh` |
| New plugin | `config/plugins.zsh` (syntax-highlighting stays last) |
| New sysmon tool | `config/monitor.zsh` (check sudo requirements first) |
| Machine-specific override | `~/.zshrc.local` (not tracked) |

## Special Directories

- `.planning/` — GSD workflow planning artifacts (not part of the shell config)
- `archive/` — Historical bash configs, read-only
- `config/` — All active zsh modules
