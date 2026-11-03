# Assets

Repository-only files used by setup scripts; not copied into `$HOME` by chezmoi.

[`wallpaper.webp`](wallpaper.webp) is selected by the [macOS defaults script](../macos/defaults.sh). That script currently refers to `$HOME/.local/share/chezmoi/install/assets/wallpaper.webp`, assuming the default checkout location. Keep the checkout and asset available while using that wallpaper.

Replacing the image alone does not change the `run_onchange` script hash. Review and rerun the relevant wallpaper command, or select the image through macOS settings, when changing the asset.
