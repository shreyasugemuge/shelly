# Zsh Dotfiles

[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)
[![Shell](https://img.shields.io/badge/shell-zsh-green.svg)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20|%20Linux-orange.svg)](#prerequisites)

A modern, modular zsh configuration with a custom prompt featuring an expressive face indicator and git integration.

## Features

**Custom prompt** with an exit-code-aware face: `[-_-]` in yellow when the last command succeeded, `[O_O]` in red when it failed. Git branch and dirty/staged status are shown inline when you're inside a repository.

**Modular configuration** split into focused files under `config/` — environment, prompt, aliases, functions, plugins, and more — all sourced automatically by `.zshrc`.

**Auto-dependency management** via `deps.zsh` — on first shell open (or once per day), automatically installs Homebrew if missing, then installs any required zsh plugins that aren't present. Completely silent when everything is already in place.

**Startup dashboard** showing system specs (OS, CPU, GPU, RAM) and network info (public/local IP, Wi-Fi SSID, DNS) on every interactive shell open.

**XDG-compliant** layout using `~/.config/zsh/` for configuration modules, keeping your home directory clean.

**One-command install** via `install.sh` that backs up existing configs, creates symlinks, and optionally sets zsh as your default shell.

## Quick Start

```bash
git clone https://github.com/shreyas613/bash_old.git ~/.dotfiles/zsh
cd ~/.dotfiles/zsh
chmod +x install.sh
./install.sh
exec zsh
```

Preview what the installer will do without making changes:

```bash
./install.sh --dry-run
```

Check which version is installed:

```bash
./install.sh --version
```

## Prerequisites

- **zsh** — macOS includes it by default; on Linux run `sudo apt install zsh`
- **git** — for branch/status info in the prompt
- **curl** — for network aliases and startup info

Homebrew and zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) are installed automatically on first shell open if missing.

## File Structure

```
.
├── .zshrc                  Main config — sources all modules
├── config/
│   ├── deps.zsh            Auto-installs Homebrew and missing plugins
│   ├── environment.zsh     Exports, locale, zsh options, NVM setup
│   ├── prompt.zsh          Custom prompt with face + git integration
│   ├── aliases.zsh         Aliases organized by category
│   ├── functions.zsh       Utility functions (extract, mkcd, pan, etc.)
│   ├── plugins.zsh         Plugin loading (autosuggestions, syntax highlighting)
│   └── sysinfo.zsh         Startup system and network dashboard
├── install.sh              Setup script (symlinks + backup)
├── VERSION                 Current version number
├── CHANGELOG.md            Release history (Keep a Changelog format)
├── CONTRIBUTING.md         How to contribute and release
├── LICENSE                 MIT License
├── .gitignore              Git ignore rules
└── archive/                Original bash config (v0.3.0, preserved)
```

## Prompt

The prompt renders on two lines:

```
[-_-] (main) user@host ~/projects/myapp
$
```

| Element     | Color        | Description                                |
|-------------|--------------|--------------------------------------------|
| `[-_-]`     | yellow       | Last command succeeded (exit code 0)       |
| `[O_O]`     | red          | Last command failed (exit code != 0)       |
| `(main)`    | green        | Current git branch                         |
| `*` / `+`   | orange       | Unstaged / staged changes                  |
| `user`      | magenta      | Your username                              |
| `@host`     | light blue   | Machine hostname                           |
| `~/path`    | cyan         | Current directory                          |

When you're not inside a git repository, the branch section is hidden.

## Useful Aliases

| Alias      | Expands to                     |
|------------|--------------------------------|
| `..`       | `cd ..`                        |
| `ll`       | `ls -lh`                       |
| `refresh`  | `exec zsh` (reload shell)      |
| `zshrc`    | Open `~/.zshrc` in your editor |
| `myip`     | Show public and local IP       |
| `gs`       | `git status`                   |
| `yell`     | `figlet` (ASCII art text)      |

See `config/aliases.zsh` for the full list.

## Useful Functions

| Function     | Description                                   |
|--------------|-----------------------------------------------|
| `pan cmd`    | Open a man page as PDF in Preview (macOS)     |
| `mkcd dir`   | Create a directory and cd into it             |
| `extract f`  | Extract any archive (.tar.gz, .zip, .7z, etc) |
| `whichip`    | Display public and local IP addresses         |
| `weather`    | Quick weather report (optional: pass a city)  |

## Customization

**Local overrides**: Create `~/.zshrc.local` for machine-specific settings that shouldn't be committed. It's automatically sourced at the end of `.zshrc`.

**Add aliases or functions**: Edit the appropriate file in `config/` or create a new `config/custom.zsh` and add a source line in `.zshrc`.

**Change colors**: Prompt colors are defined in `config/prompt.zsh` using `%F{color}` codes.

## Uninstall

```bash
./install.sh --uninstall
```

This removes the symlinks and tells you where your backup is so you can restore your previous config.

## Versioning

This project follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for the full release history and [CONTRIBUTING.md](CONTRIBUTING.md) for the release process.

| Version | Date       | Description                              |
|---------|------------|------------------------------------------|
| v1.2.0  | 2026-02-17 | Auto-deps, startup system/network dashboard |
| v1.1.0  | 2026-02-16 | Plugins, lazy NVM, cached compinit       |
| v1.0.0  | 2026-02-16 | Complete zsh rewrite, modular config     |
| v0.3.0  | 2017-04-14 | Last bash version (archived)             |
| v0.2.0  | 2017-03-xx | Added network mode, college aliases      |
| v0.1.0  | 2017-02-xx | Initial bash config                      |

## Migration from Bash

The original bash configuration is preserved in `archive/` for reference. See `archive/.bashrc` for the legacy setup. The [CHANGELOG.md](CHANGELOG.md) documents exactly what was removed and why.

## License

[MIT](LICENSE) — Shreyas Ugemuge, 2017–2026

## Author

Shreyas
