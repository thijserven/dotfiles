# eza

Catppuccin Macchiato colors for terminal file listings.

## Files

[theme.yml](theme.yml) deploys to `~/.config/eza/theme.yml`. Defines file kinds, permissions, sizes, owners, Git status, and file-type colors. Filename and extension override sections are placeholders only.

## Usage

```sh
eza --long --git --icons
eza --tree --level=2
```

[Zsh](../zsh/README.md) supplies listing aliases and eza directory previews for fzf. Icons need a compatible terminal font.

[Application index](../README.md)
