# Hammerspoon

macOS automation deployed to `~/.hammerspoon/`; excluded on Linux. [`init.lua`](init.lua) disables native login startup, hides the menu icon, and loads keyboard and SketchyBar menu behavior. Repository-managed LaunchAgent owns startup and recovery. Grant Hammerspoon macOS permissions needed for event taps and app control.

## Modules

| File                                                     | Responsibility                                                                                                |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| [`caps_lock.lua`](caps_lock.lua)                         | Map Caps Lock to F18 through `hidutil`, preserving other mappings                                             |
| [`hyperkey.lua`](hyperkey.lua)                           | Hold Caps Lock for Hyper (`cmd+alt+ctrl+shift`); tapping sends no key; reapply mapping after wake or USB attachment |
| [`sketchybar_menu_guard.lua`](sketchybar_menu_guard.lua) | Keep cursor outside native menu-bar reveal zone; Option bypasses guard |
| [`sketchybar_audio_keys.lua`](sketchybar_audio_keys.lua) | Enable popup hotkeys from published visibility and process liveness; retain polling timers |
| [`audio_controls.lua`](audio_controls.lua) | Coalesce deferred CoreAudio changes and manage held-volume-key repeat |
| [`brightness_controls.lua`](brightness_controls.lua) | Serialize brightness CLI writes, repeat popup keys, and sample selected brightness slider during drags |
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

Brightness popup captures `-`, `=` and Shift+`=` for built-in display brightness
only while `brightness-popup` lease is open. `[` and `]` control keyboard
backlight while its availability lease is open. Controls change manual levels,
including when macOS auto brightness is enabled; native automatic settings remain
untouched, and macOS may adjust brightness again later.
Steps are 5 points, with a 300 ms initial delay and 75 ms repeat interval; latest
held direction wins. Brightness takes keyboard precedence over audio when both
popups are open. Slider sampling runs every 25 ms and checks mouse-down geometry
so only the selected slider changes. Component release calls
`require("brightness_controls").commit(target, percentage, sequence)` through Hammerspoon's
bundled `hs` CLI, covering short clicks and invalidating stale preview callbacks.
All writes use one serialized, coalescing queue for Homebrew `brightness` and
`rakalex/mac-brightnessctl/mac-brightnessctl`; no separate component setter is used.
Display writes target the online built-in display's explicit ID; keyboard controls
require detected backlight hardware and a valid CLI reading. Key sequences refresh
status before applying their first delta. Display slider selection and release
commits require the popup lease; keyboard controls also require availability.
`brightness_state` publishes acknowledged `DISPLAY`/`KEYBOARD` values,
`ERROR=true/false`, and `DRAGGING=true` while drag or key writes are pending.
Upstream keyboard setter reports requested values without verifying hardware success.
`INPUT=pointer` (also `POINTER=true`) marks labels-only events throughout pointer
interaction, release writes, and final `DRAGGING=false` acknowledgement; these events
must never set slider percentages. Other sources are `keyboard` and `refresh`.
Components defer status rendering until `DRAGGING=false`. Release waits for component
commit before settling, with a one-second fallback for releases outside the slider.
Delayed commits are rejected while a newer mouse gesture is held. Brightness CLIs
come from the Homebrew package lifecycle; unsupported devices report no value.

## Changes and startup

Edit Vicinae app shortcuts in `home/private_dot_config/vicinae/settings.json` under `providers.applications.entrypoints`, using app entrypoint IDs and Vicinae shortcut strings. Firefox's release binding lives in `hyperkey.lua`; do not also bind it in Vicinae. Hyper is `super+control+alt+shift` on macOS. Deploy both configs and reload Hammerspoon:

```sh
chezmoi diff ~/.hammerspoon ~/.config/vicinae/settings.json
chezmoi apply ~/.hammerspoon ~/.config/vicinae/settings.json
open -a Hammerspoon
```

Use Hammerspoon's Reload Config action after deployment. `hs.autoLaunch(false)` disables native login startup; repository-managed [LaunchAgent](../.chezmoiscripts/.README.md#desktop-startup-on-macos) owns startup and automatic recovery after quit/crash. Stop supervision before intentionally quitting for maintenance.
