# Prompt

Shelly's prompt is a two-line design that packs meaning into minimal visual elements.

## Layout

```
[-_-] (main *?) user@host ~/projects/myapp
$
```

## Elements

| Element     | Color   | Meaning                           |
|-------------|---------|-----------------------------------|
| `[-_-]`     | yellow  | Last command succeeded (exit 0)   |
| `[O_O]`     | red     | Last command failed (exit != 0)   |
| `(main)`    | green   | Clean git branch                  |
| `(main *)`  | orange  | Unstaged changes                  |
| `(main +)`  | orange  | Staged changes                    |
| `(main ?)`  | orange  | Untracked files                   |
| `user@host` | gray    | Username and hostname (muted)     |
| `~/path`    | default | Current directory                 |

## Design Philosophy

Color conveys meaning, not decoration:
- **Yellow/red face** signals exit status at a glance
- **Green/orange git** signals repo state
- **Everything else** stays muted or default terminal color

The branch section is hidden entirely outside git repositories.

## Path Truncation

Deep paths are automatically shortened:

```
~/very/deep/nested/project/src → ~/…/project/src
```

## Customization

Edit `config/prompt.zsh`. Colors use native zsh `%F{color}` syntax:

```zsh
%F{yellow}   # yellow
%F{red}      # red
%F{green}    # green
%F{208}      # orange (256-color)
%F{240}      # dim gray (256-color)
%f           # reset to default
```
