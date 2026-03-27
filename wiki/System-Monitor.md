# System Monitor (sysmon)

`sysmon` launches an iTerm2 tab with a two-pane system monitoring dashboard.

> **Requires** iTerm2 with Python API enabled: Preferences > General > Magic > Enable Python API

## Layout

```
┌──────────────────────────┬──────────────────────┐
│                          │                      │
│  btop                    │  mactop              │
│  CPU cores + memory      │  CPU/GPU temp        │
│  + network               │  Power draw          │
│                          │  Frequency           │
│                          │  ANE + thermals      │
│                          │                      │
└──────────────────────────┴──────────────────────┘
```

| Pane        | Tool   | Shows                                          |
|-------------|--------|------------------------------------------------|
| Left        | btop   | All CPU cores (braille graphs), memory, network |
| Right       | mactop | CPU/GPU temperature, power draw, frequency, ANE |

## Commands

| Command         | Description                            |
|-----------------|----------------------------------------|
| `sysmon`        | Launch or focus existing tab           |
| `sysmon kill`   | Close the sysmon tab                   |
| `sysmon status` | Check installed tools and tab state    |
| `sysmon help`   | Quick reference                        |
| `sysmon-old`    | Legacy layout (nvtop + macmon)         |

## Tools

### btop
- Config is **force-written** on every launch (`~/.config/btop/btop.conf`) — this is intentional to prevent sticky-state bugs
- Shows CPU, memory, and network — disks and process table are hidden
- btop has no `--conf` CLI flag — it always reads from the config path above

### mactop
- Auto-detects Apple Silicon — no config file needed
- Shows metrics that btop can't: GPU utilization, frequency, ANE activity, thermal state, power draw
- No sudo required

## Behavior

- **Tab reuse** — if a sysmon tab is already open, `sysmon` focuses it instead of creating a new one
- **Inactive pane dimming** — disabled while sysmon is open, restored on `sysmon kill`
- **Session tracking** — state stored in `~/.cache/zsh/sysmon.session_id`

## Legacy Layout

`sysmon-old` preserves the older nvtop + macmon layout with its own state file. Useful if you prefer the GPU-focused view.
