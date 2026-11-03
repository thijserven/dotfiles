# AeroSpace

macOS tiling window manager. [Configuration](aerospace.toml) deploys to `~/.config/aerospace/aerospace.toml`.

## Configuration

- Persistent workspaces `1`–`5`, automatic tiling orientation, 15px inner gaps.
- Top gap reserves 42px for [SketchyBar](../sketchybar/README.md) and spacing.
- Startup and workspace changes send `aerospace_workspace_change` events to SketchyBar. Homebrew owns SketchyBar startup.
- `start-at-login = false`: repository-managed [LaunchAgent](../../.chezmoiscripts/.README.md#desktop-startup-on-macos) owns startup and automatic recovery after quit/crash.

## Usage

| Shortcut | Action |
| --- | --- |
| `Ctrl+H/J/K/L` | Focus left/down/up/right |
| `Ctrl+Cmd+H/J/K/L` | Move window |
| `Ctrl+/`, `Ctrl+,` | Tile or accordion layout |
| `Ctrl+-/=`, `Ctrl+Shift+-/=` | Resize width or height |
| `Cmd+Ctrl+N`, `M`, `,`, `.`, `/` | Workspaces 1–5; modifiers apply to each key |
| `Alt+Tab` | Previous workspace |
| `Alt+Shift+Tab` | Move workspace to next monitor |
| `Cmd+;` | Service mode |

Service mode: `Esc` reloads config and returns to main mode; `r` resets layout; `f` toggles floating. `Backspace` closes every window except current window.

Launch with `open -a AeroSpace`; reload with `aerospace reload-config`. Grant macOS Accessibility permission when requested.

`Ctrl+T` references `~/.config/aerospace/auto_tile_3.sh`, which is not tracked here. Binding needs that local script before use.

[Application index](../README.md)
