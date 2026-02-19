# Contributing

Thanks for your interest in contributing to this dotfiles project.

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
   - `config/functions.zsh` — shell functions
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

1. Update `VERSION` file with the new version number
2. Move `[Unreleased]` entries in `CHANGELOG.md` to a new version section
3. Update comparison links at the bottom of `CHANGELOG.md`
4. Commit: `chore: bump version to x.y.z`
5. Tag: `git tag -a vx.y.z -m "Release vx.y.z"`
6. Push: `git push origin master --tags`

## Guidelines

- Keep aliases short and memorable
- Guard macOS-specific commands with `[[ "$OSTYPE" == darwin* ]]`
- Don't commit secrets, credentials, or machine-specific paths
- Use `~/.zshrc.local` for personal overrides
- Add comments explaining non-obvious aliases or functions
