# Contributing

Thanks for your interest in contributing to Shelly.

## Versioning

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR** (x.0.0) — breaking changes to config structure or shell compatibility
- **MINOR** (0.x.0) — new features, aliases, or functions (backward-compatible)
- **PATCH** (0.0.x) — bug fixes, typo corrections, documentation updates

## Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-change`
3. Make your changes in the appropriate config module:
   - `config/environment.zsh` — exports, options, PATH
   - `config/prompt.zsh` — prompt appearance and behavior
   - `config/aliases.zsh` — command aliases
   - `config/iterm2.zsh` — shared iTerm2 tab/session utilities
   - `config/functions.zsh` — utility functions (pan, mkcd, extract, etc.)
   - `config/release.zsh` — versioning and release CLI (`shelly` command)
   - `config/devterm.zsh` — dev workspace (`devterm` command)
   - `config/plugins.zsh` — plugin loading
   - `config/monitor.zsh` — system monitor dashboard (`sysmon` command)
   - `config/sysinfo.zsh` — startup splash screen
4. Test your changes: `exec zsh` to reload
5. Update `CHANGELOG.md` under `[Unreleased]`
6. Commit with a clear message
7. Open a pull request

## Commit Messages

Use clear, descriptive commit messages:

```
feat: add docker aliases to aliases.zsh
fix: correct locip fallback on Linux
docs: update prompt color reference in README
chore: bump version to 1.1.0
```

Prefixes: `feat`, `fix`, `docs`, `chore`, `refactor`, `style`, `test`

## Release Process

Use the automated release command:

```bash
shelly release <major|minor|patch>
```

This handles: VERSION bump, CHANGELOG sectioning, commit, tag, and push.
Ensure the `[Unreleased]` section in CHANGELOG.md has entries before releasing.

## Guidelines

- Keep aliases short and memorable
- Guard macOS-specific commands with `$IS_MACOS` / `$IS_LINUX` (set in `.zshrc`)
- Don't commit secrets, credentials, or machine-specific paths
- Use `~/.zshrc.local` for personal overrides
- Add comments explaining non-obvious aliases or functions
