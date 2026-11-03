# Starship

Shell prompt using Catppuccin Macchiato palette and mostly text-based module symbols.

## Files

[starship.toml](starship.toml) deploys to `~/.config/starship/starship.toml`. Customizes success/error/vi-mode characters, Git status markers, and language/cloud/tool symbols. Module symbols do not enable modules by themselves; visibility and unspecified options follow Starship defaults.

## Usage

[Zsh environment module](../zsh/env.zsh.tmpl) exports `STARSHIP_CONFIG` to this nondefault path and initializes Starship. Other shells must set that path and initialize Starship separately.

```sh
starship explain
starship timings
```

Config does not set directory truncation or command-duration threshold; those follow installed Starship version's defaults.

[Application index](../README.md)
