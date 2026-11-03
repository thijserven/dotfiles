# Shared templates

Reusable source fragments live here; chezmoi does not deploy this special directory directly. Current contents define VS Code configuration shared by macOS and Linux.

## VS Code

| File                                                 | Purpose                                                           |
| ---------------------------------------------------- | ----------------------------------------------------------------- |
| [`vscode/settings.json`](vscode/settings.json)       | Editor and extension settings                                     |
| [`vscode/keybindings.json`](vscode/keybindings.json) | Keyboard shortcuts                                                |
| [`vscode/extensions.txt`](vscode/extensions.txt)     | Extension IDs, one per line; blank lines and `#` comments allowed |

Thin `include` templates deploy settings and keybindings to:

- macOS: [`Library/Application Support/Code/User/`](../Library/Application%20Support/Code/User/), targeting `~/Library/Application Support/Code/User/`.
- Linux: [`private_dot_config/Code/User/`](../private_dot_config/Code/User/), targeting `~/.config/Code/User/`.

Edit shared files rather than copying settings between target directories. Platform exclusions select the appropriate target.

The [VS Code extension script](../.chezmoiscripts/.README.md) embeds the extension-list hash and installs missing extensions after deployment. Existing extensions are not removed; an unavailable `code` CLI skips installation. `README.md` files here are documentation, not template inputs.
