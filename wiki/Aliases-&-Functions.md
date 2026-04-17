# Aliases & Functions

## Aliases

Defined in [`config/aliases.zsh`](https://github.com/shreyasugemuge/shelly/blob/master/config/aliases.zsh).

### Navigation
| Alias | Command | Description |
|-------|---------|-------------|
| `..` | `cd ..` | Go up one directory |
| `...` | `cd ../..` | Go up two directories |
| `ll` | `eza --long --header --git --icons --group-directories-first --color-scale=size ...` | Beautiful long listing — smart size units (B/K/M/G), size-gradient coloring, git status column, Nerd Font icons, dirs grouped first. Falls back to `ls -lh` if `eza` isn't installed. |
| `la` | `ls -a` | Short listing with hidden files |
| `lla` | `ls -la` | Plain long listing with hidden files |
| `tre` | `tree -C -L 2` | Colorized directory tree (2 levels) |

### Git
| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Short status |
| `gb` | `git branch` | List branches |
| `gco` | `git checkout` | Checkout |
| `gsw` | `git switch` | Switch branch |

### Network
| Alias | Command | Description |
|-------|---------|-------------|
| `myip` | `curl ...` | Show public and local IP |
| `globip` | `curl ifconfig.me` | Public IP only |
| `locip` | auto-detected | Local IP (detects active interface) |

### Shell
| Alias | Command | Description |
|-------|---------|-------------|
| `refresh` | `exec zsh` | Reload shell config |
| `zshrc` | `$EDITOR ~/.zshrc` | Edit zshrc |
| `zsh-bench` | `time zsh -i -c exit` | Benchmark startup time |

## Functions

Defined in [`config/functions.zsh`](https://github.com/shreyasugemuge/shelly/blob/master/config/functions.zsh).

| Function | Description |
|----------|-------------|
| `devterm` | Dev workspace — see [[Dev Workspace]] |
| `sysmon` | System monitor — see [[System Monitor]] |
| `extract <file>` | Extract any archive format (tar, zip, gz, bz2, xz, 7z, etc.) |
| `mkcd <dir>` | Create directory and cd into it |
| `pan <command>` | Open man page as PDF in Preview |
| `portfind <port>` | Find what's listening on a port (validates 1-65535) |
| `whichip` | Show public IP, local IP, and active interface |
| `weather [city]` | Terminal weather forecast via wttr.in |
| `cc` | Run Claude Code with notification on exit |
| `ccnotify` | Send an iTerm2 notification |
| `iterm-setup` | One-time installer for iTerm2 shell integration |
