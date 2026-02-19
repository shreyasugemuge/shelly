# Claude Context — Zsh Dotfiles

## What This Is

A modular zsh configuration managed by Shreyas Ugemuge. It lives in `~/.dotfiles/zsh` and gets symlinked into place by `install.sh`. The repo name (`bash_old`) is historical — this is pure zsh now.

## Repo Layout

- `.zshrc` — entry point, sources all modules in `config/`
- `config/` — modular config files (environment, prompt, aliases, functions, plugins, deps, sysinfo)
- `install.sh` — setup script with backup, `--dry-run`, `--uninstall`
- `deploy.sh` — one-command push, tag, and GitHub release
- `archive/` — legacy bash config preserved for reference, do not modify

## Key Design Decisions

- **Color philosophy**: color should convey meaning, not decoration. The prompt face (yellow/red) signals exit status, git indicators (green/orange) signal repo state. Everything else (user, host, path) stays muted/default. Syntax highlighting from the zsh plugin handles command coloring.
- **Startup dashboard** (`sysinfo.zsh`): labels are dim gray, values are default terminal color. No bold, no cyan headers.
- **macOS-first, Linux-compatible**: guard platform-specific code with `[[ "$OSTYPE" == darwin* ]]` and always provide a Linux fallback.
- **XDG-compliant**: config lives under `~/.config/zsh/`, not directly in `$HOME`.
- **Performance matters**: NVM is lazy-loaded, compinit is cached daily, deps check runs once per day.

## Versioning & Releases

Follows semver. See CONTRIBUTING.md for the full process. Quick version:
1. Update `VERSION` file
2. Update `CHANGELOG.md` (move Unreleased → new version section)
3. Commit: `chore: bump version to x.y.z`
4. Tag + push: `git tag -a vx.y.z -m "Release vx.y.z"` then `git push origin master --tags`
5. Or use `deploy.sh` which handles push + tag + GitHub release in one command

## Commit Style

Conventional-ish prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `style:`

## Remotes

- `origin` — `shreyas613/bash_old` (Shreyas's fork, where work happens)
- `upstream` — `shreyasugemuge/bash` (canonical repo)

## Things to Watch Out For

- Never commit secrets, credentials, or machine-specific paths
- The `ls` alias in `aliases.zsh` has BSD/GNU detection — don't simplify it
- `plugins.zsh` must source syntax-highlighting LAST (zsh requirement)
- `~/.zshrc.local` is for machine-specific overrides and is not tracked in git
