# Ghostty

Terminal configuration with Catppuccin Macchiato, JetBrains Mono at 15pt, saved window state, and dimmed unfocused splits.

## Files

[config](config) deploys to `~/.config/ghostty/config`.

## Usage

| Shortcut | Action |
| --- | --- |
| `Super+Alt+Arrow` | Create split in direction |
| `Super+Arrow` | Focus split in direction |
| `Super+Alt+Space` | Global quick-terminal toggle |

On macOS, `Super` means Command. Quick terminal has no animation or autohide and remains on its current Space. Global shortcuts may need macOS permissions.

Config contains repeated assignments: final `quick-terminal-position = center` overrides `bottom`; final `window-decoration = true` overrides `none`. Close confirmation is disabled.

`macos-icon = blueprint` is selected. Config also names `~/.config/ghostty/icons/whiskers_1024x1024.png`, but that asset is not tracked here. Font must be installed separately.

[Zsh](../zsh/README.md) and [Starship](../starship/README.md) own shell behavior and prompt.

[Application index](../README.md)
