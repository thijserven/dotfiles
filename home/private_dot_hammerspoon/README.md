# Hammerspoon

macOS automation deployed to `~/.hammerspoon/`; excluded on Linux. [`init.lua`](init.lua) disables native login startup, hides the menu icon, and loads keyboard and SketchyBar menu behavior. Repository-managed LaunchAgent owns startup and recovery. Grant Hammerspoon macOS permissions needed for event taps and app control.

## Modules

| File                                                     | Responsibility                                                                                                |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| [`caps_lock.lua`](caps_lock.lua)                         | Map Caps Lock to F18 through `hidutil`, preserving other mappings                                             |
| [`hyperkey.lua`](hyperkey.lua)                           | Tap Caps Lock for Escape; hold for Hyper (`cmd+alt+ctrl+shift`); reapply mapping after wake or USB attachment |
| [`sketchybar_menu_guard.lua`](sketchybar_menu_guard.lua) | Keep cursor outside native menu-bar reveal zone; Option bypasses guard |
| [`sketchybar_audio_keys.lua`](sketchybar_audio_keys.lua) | Enable popup hotkeys from published visibility and process liveness; retain polling timers |
| [`audio_controls.lua`](audio_controls.lua) | Coalesce deferred CoreAudio changes and manage held-volume-key repeat |
| [`sketchybar_slider_preview.lua`](sketchybar_slider_preview.lua) | Query dragged volume slider and preview its percentage label |
| [`sketchybar.lua`](sketchybar.lua) | Send shared SketchyBar events and retain tasks until completion |

[Vicinae settings](../private_dot_config/vicinae/settings.json) owns Hyper+Return for cmux, Hyper+C for VS Code, and Hyper+O for OpenCode. Vicinae must be running and have macOS permissions for global shortcuts. Hammerspoon owns Hyper+B for Firefox: it consumes B and launches or focuses Firefox only after Caps Lock, B, and Command/Option/Control/Shift release. This prevents Option at startup from triggering Troubleshoot Mode. Wake cancels pending launches.

Hyper+1 through Hyper+9 and Hyper+0 in `init.lua` send SketchyBar's
`popup_toggle` event with `SLOT=1` through `SLOT=10`. SketchyBar owns slot
assignment and publishes current popup shortcuts to
`~/.cache/sketchybar/keybindings.json`; Vicinae's keybindings extension reads
that optional source independently of static shortcuts.

`sketchybar_audio_keys.lua` also captures unmodified Escape while any shared
SketchyBar popup is open and sends `popup_close_all`; otherwise Escape passes through.
Unmodified `t` starts/cancels the speed test only while network popup is open;
autorepeat is ignored. It captures `-`, `+` (also `=`), and `m` only while
SketchyBar's audio popup is visible: volume down/up by 5 points and mute toggle.
Native CoreAudio avoids per-volume-key subprocesses. Held volume keys repeat at
about 13 steps/second; the latest held direction wins. Mute publishes switch state immediately;
mute ignores repeats. Popup keyboard controls use native `hs.hotkey` bindings;
timestamp age never disables an open popup. A two-second process check disables
bindings if SketchyBar exits. Closed popups leave normal typing unchanged.

## Changes and startup

Edit Vicinae app shortcuts in `home/private_dot_config/vicinae/settings.json` under `providers.applications.entrypoints`, using app entrypoint IDs and Vicinae shortcut strings. Firefox's release binding lives in `hyperkey.lua`; do not also bind it in Vicinae. Hyper is `super+control+alt+shift` on macOS. Deploy both configs and reload Hammerspoon:

```sh
chezmoi diff ~/.hammerspoon ~/.config/vicinae/settings.json
chezmoi apply ~/.hammerspoon ~/.config/vicinae/settings.json
open -a Hammerspoon
```

Use Hammerspoon's Reload Config action after deployment. `hs.autoLaunch(false)` disables native login startup; repository-managed [LaunchAgent](../.chezmoiscripts/.README.md#desktop-startup-on-macos) owns startup and automatic recovery after quit/crash. Stop supervision before intentionally quitting for maintenance.
