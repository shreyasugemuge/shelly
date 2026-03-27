# Troubleshooting

## iTerm2 Python API

**Problem:** `sysmon` or `devterm` prints "non-iTerm mode" or fails to create tabs.

**Fix:** Enable the Python API in iTerm2:
1. Open iTerm2 Preferences (Cmd+,)
2. Go to General > Magic
3. Check "Enable Python API"

Also make sure you're running the command inside iTerm2, not Terminal.app or another terminal emulator.

## Slow Shell Startup

**Problem:** Shell takes more than 500ms to start.

**Diagnose:**
```bash
zsh-bench   # alias for: time zsh -i -c exit
```

**Common causes:**
- **NVM** — already lazy-loaded by Shelly; if you have a separate NVM init in `~/.zshrc.local`, remove it
- **Stale cache** — delete `~/.cache/zsh/sysinfo_cache` to force a fresh build
- **compinit** — the completion dump is cached daily; a fresh `exec zsh` after a day's first launch is normal

## compinit Insecure Directory Warning

**Problem:** Interactive prompt about insecure directories on shell open.

**Fix:** This is usually caused by group-writable Homebrew directories after `brew reinstall zsh-completions`. Shelly passes `-u` to compinit to suppress this. If you still see it, run:

```bash
chmod go-w "$(brew --prefix)/share"
chmod -R go-w "$(brew --prefix)/share/zsh"
```

## Sysinfo Cache

**Problem:** Startup splash shows stale data.

**Fix:** Delete the cache:
```bash
rm -rf ~/.cache/zsh/sysinfo_cache
exec zsh
```

The cache auto-refreshes: hardware info on reboot, package count every hour, git streak every 5 minutes.

## devterm Tab Won't Close

**Problem:** `devterm kill` or `devterm -s kill` says "already closed" but a tab is still open.

**Fix:** The session tracking file may be out of sync. Close the tab manually in iTerm2, then remove the state file:

```bash
rm ~/.cache/zsh/devterm.session_id        # standard mode
rm ~/.cache/zsh/devterm-split.session_id  # split mode
```

## btop Config Gets Overridden

**This is intentional.** Shelly force-writes `~/.config/btop/btop.conf` on every `sysmon` launch to prevent sticky-state bugs. If you want custom btop settings outside of sysmon, launch btop directly instead of through `sysmon`.

## Syntax Highlighting Not Working

**Problem:** No colors on commands.

**Fix:** `zsh-syntax-highlighting` must be sourced last in `plugins.zsh`. If you've modified `config/plugins.zsh`, make sure the syntax-highlighting source line is at the bottom. There's a guard comment — don't reorder.

## Platform-Specific Issues

Use `$IS_MACOS` and `$IS_LINUX` for platform checks in your `~/.zshrc.local`:

```bash
if $IS_MACOS; then
    # macOS-specific config
fi
```

These booleans are set once in `.zshrc` — don't use `$OSTYPE` checks.
