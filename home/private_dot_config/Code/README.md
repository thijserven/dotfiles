# Visual Studio Code

Linux target wrappers for shared VS Code configuration. This directory is excluded on macOS; [macOS wrappers](../../Library/Application%20Support/Code/User/) target `~/Library/Application Support/Code/User/` instead.

## Files

| Source | Role |
| --- | --- |
| [User/settings.json.tmpl](User/settings.json.tmpl) | Includes shared settings verbatim; renders to `~/.config/Code/User/settings.json` |
| [User/keybindings.json.tmpl](User/keybindings.json.tmpl) | Renders shared keybindings with chezmoi data |
| [Shared templates](../../.chezmoitemplates/vscode/) | Source of truth for settings, keybindings, extension list |
| [Extension installer](../../.chezmoiscripts/common/run_onchange_after_40_vscode_extensions.sh.tmpl) | Installs listed extensions when script or embedded list hash changes |

## Usage

Edit shared templates, not platform wrappers, for changes that should reach both platforms. Keep wrappers aligned.

Shared settings select Catppuccin Macchiato, JetBrains Mono, Prettier format-on-save, ESLint fixes, delayed autosave, right sidebar, and disabled telemetry. Shared keybindings currently contain `[]`, leaving defaults unchanged.

Extension IDs live in [extensions.txt](../../.chezmoitemplates/vscode/extensions.txt). Preview deployment with `chezmoi diff`; VS Code's `code` CLI must be available for extension installation and Git's configured editor.

[Application index](../README.md)
