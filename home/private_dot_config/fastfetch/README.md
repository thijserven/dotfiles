# Fastfetch

Grouped system-information display with colored tree-style labels.

## Files

[config.jsonc](config.jsonc) deploys to `~/.config/fastfetch/config.jsonc`. Groups hardware, desktop/session, and user/OS/network modules. Uses Nerd Font glyphs; no custom image path is configured despite introductory example comments.

## Usage

```sh
fastfetch
fastfetch --config ~/.config/fastfetch/config.jsonc
```

Module availability depends on platform and hardware. Public-IP lookup uses network access with a 1000ms timeout; output also includes local IP and Wi-Fi SSID. Review output before sharing it.

[Application index](../README.md)
