# SketchyBar

Configuration lives in `init.lua`; palette and shared popup styles live in
`theme.lua`; reusable UI code lives in `ui/`. `ui/popup.lua`
shares row padding, spacers, separators and mouse open/close handling between
network and volume. New popups use
`require("ui.popup")(sbar, theme, owner, "feature")`, then assign `on_open`/`on_close`
callbacks when needed. `popup.columns` creates shared left-label/right-value rows;
feature-specific widths and controls stay in `components/`.
`popup.keyboard_state("audio-popup")` opts into initial, open/close and routine
state publication; feature callbacks only manage feature state.
`services/network.lua` keeps counter math, units and signal icons independent of UI.
`services/aerospace.lua` owns workspace ordering, shell quoting and binding formatting;
`components/aerospace.lua` keeps reconciliation and popup presentation.
`services/speedtest.lua` owns asynchronous speed-test start/cancel/completion state;
network widget owns presentation. Shell helpers live in `services/` and handle
native macOS commands and speed-test process control.
`components/battery.lua` arranges clock
and battery; `coffee.lua` owns keep-awake commands and state. Right-side order
(left to right) is system load, coffee, network, volume, battery, then a 5-point gap and clock.
`ui/shortcuts.lua` reverses popup registration order to match right-side rendering:
Hyper+1 opens system load, Hyper+2 toggles caffeinate, Hyper+3 opens network,
Hyper+4 opens volume, Hyper+5 opens Battery settings, and Hyper+6 opens macOS Clock.
Battery and clock clicks run the same actions; clock displays `Friday Oct 30 17:37`.
Moving components in `init.lua` automatically renumbers
registered actions; passive items consume no slots. Contextual AeroSpace service help keeps its own bindings.
Hammerspoon dispatches Hyper+1–9 and Hyper+0 (slot 10) through `popup_toggle`.
Holding Hyper shows small numbered hints at each registered icon's lower-right
edge, with 2px extra bottom clearance; releasing Hyper hides them. Hints use the same dynamic slot registry and
zero-width overlays, so bar layout stays unchanged.
Keyboard opening closes other numbered popups. The same registry publishes
`~/.cache/sketchybar/keybindings.json` for Vicinae; reload its keybindings command
after changing bar order.
Feature icons and clock form separate sections; center stays clear for notch.
Widgets keep feature state local and separate refresh, rendering and click actions
into named functions where needed. Shared UI helpers own UI behavior, not network
or audio commands. `sketchybarrc` only sets
Homebrew PATH and replaces itself with central mise Lua via `mise exec`. No per-event shell plugins.

Patterns follow [SbarLua's upstream examples](https://github.com/FelixKratz/SbarLua/tree/main/example):
batched startup, one event loop, native event subscriptions, asynchronous
`sbar.exec`. Clock uses Lua's standard library. Battery polls once per minute;
AeroSpace reconciles every ten seconds and on workspace/wake events. Service mode
replaces workspace numbers with ‘Service mode, press "b" for keybindings’,
using 11pt Hack Nerd Font Bold and the same text color as workspace numbers.
`b` or clicking the label toggles a keybindings popup using the same `ui.popup`
layout and mouse handling as network/audio. Exiting service mode closes it.
Each opening reads `aerospace config --get mode.service.binding --json` and lists
sorted keys with readable titles and key aliases matching Vicinae's AeroSpace
parser (for example, `ctrl + h` and `Join with left`), omitting `mode main`
from action titles. Service popup uses 480px columns and shared 12px bottom padding,
matching network/audio. All three popups defer visibility until their async content
is ready, avoiding an initial partial layout followed by visible resizing.
No duplicate binding list: deployed
`aerospace/aerospace.toml` is source of truth. Run `aerospace reload-config` after
changing that file so AeroSpace and popup both use the updated bindings.
`k` raises volume; `j` lowers volume.
In service mode, `t` returns focused floating window to tiling and exits to main;
`f` toggles floating/tiling.
Main mode restores workspace numbers without a mode label.
AeroSpace's `on-mode-changed` callback updates visibility immediately; periodic
reads restore state after bar restarts. Failed reads preserve last known state.
Missing AeroSpace never blocks clock, audio or battery. macOS CLI calls remain necessary
for battery and audio; they run asynchronously, not through `io.popen` or `os.execute`.

App icons reuse [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font)
release `v3.0.12` Lua mapping through checksum-verified chezmoi external.
Homebrew installs its font. Unknown apps use SF Symbols. No third-party widget
framework: upstream examples cover status widgets; AeroSpace and device popup
need small local adapters. Upstream calls SbarLua early development, not a stable
versioned API; its source revision is pinned in installation script.

## Network

`components/network.lua` shows four Wi-Fi signal levels, Ethernet for wired primary
connections, or separate offline/other-interface icons. Popup uses 13-point text,
muted stat labels and normal text-colored values. Shows connection/service, live
receiving/sending rates, downloaded/uploaded totals, local IP and gateway.
Totals are cumulative interface counters, not session totals. Popup padding
uses sides 12 and bottom 12 like volume; top spacer is 10 to compensate for
shorter header and match volume's visible top inset. Settings and speedometer use normal
text color; speedometer uses pink accent only while test runs.
“Open Wifi Settings” opens macOS Wi-Fi settings. Click again or leave popup to close.

Click speedometer in popup header to run installed Ookla CLI:
`speedtest --accept-license --accept-gdpr --format=json --progress=no`.
These flags accept Ookla's license and privacy terms without first-run
prompts. Test uses internet traffic and shows download/upload bandwidth, ping and
packet loss on completion. Click speedometer again to cancel only this popup's
speedtest process; icon returns to normal text color and late results are ignored.
Next test can start once cancelled process exits.
While network popup is open, press `t` to start/cancel using the same control.
Holding `t` ignores autorepeat; closed popup leaves typing unchanged.
Hammerspoon uses a short-lived local popup-state lease, not subprocess polling.
Reload Hammerspoon after deployment.
Failures show a Terminal troubleshooting hint. Tests never run automatically.

`services/network.sh` samples native macOS network state and byte counters every
three seconds, plus Wi-Fi changes/wake. Live throughput measures primary-interface
traffic, separately from speed test results. First sample and interface changes
need another sample. Background sampling makes no external requests. IPv6 fallback
uses first interface address, which may be link-local. No network settings are changed.

CoreWLAN supplies signal strength without deprecated `airport` tooling. Recent
macOS versions may hide SSID without Location Services permission for host process;
popup then says “SSID hidden by macOS”. No permission bypass. Primary IPv4 service
falls back to IPv6; VPNs may appear as “Other”.

## Escape closes popups

Press unmodified Escape while any shared popup is open to close all popups,
including AeroSpace service help. Tap-generated Escape from Hyper is ignored by
popup handling, so tapping Hyper alone does not close popups.
Otherwise Escape passes to the focused app.
Hammerspoon reads the shared popup-state lease; no subprocess polling. Holding
Escape sends only one close event. Reload Hammerspoon after deployment.

## Audio keyboard controls

While audio popup is visible, `-` lowers volume by 5 percentage points, `+`
(or unshifted `=`) raises it by 5, and `m` toggles mute. Volume clamps to 0–100.
Changing volume with these keys or the slider also unmutes audio.
While the mouse button is held in the audio popup, Hammerspoon samples the native
slider percentage every 25ms and updates its label as it moves. Calls launch
SketchyBar directly without shell startup. Only one async query/update runs at a
time; unchanged percentages skip writes. Actual slider
volume still commits on release, matching SketchyBar's native click event.
Hammerspoon enables native `hs.hotkey` bindings from atomically published popup
state, without a custom keyboard event tap. Audio changes use native CoreAudio,
deferred outside hotkey callbacks. Volume keys apply one 5% step immediately, wait 300ms, then repeat every 75ms (about 13 steps
per second); the most recently pressed direction wins, and releasing it resumes
any earlier held direction. Mute ignores autorepeat and publishes switch state
directly to SketchyBar. Bindings change only when popup state changes, not when
heartbeat timestamps age. A two-second process check disables bindings if this
user's SketchyBar exits. Closed popups and modified shortcuts leave typing alone.
Shift is accepted only for `+`.
Uses existing Hammerspoon Accessibility permission;
Secure Input can block capture. Reload Hammerspoon after deployment.

## Keep awake

Coffee icon or **Hyper+2** directly toggles `caffeinate -di`: prevent idle
system/display sleep while enabled. No popup; icon color shows state.
The `coffee_toggle` event toggles the assertion directly.
Pink uses AeroSpace's active accent; normal text color means off. State reconciles
every ten seconds and after wake/reload. Only this bar's caffeinate process is
stopped; assertions also end when SketchyBar exits. Closing lid or explicitly
sleeping Mac still overrides idle-sleep prevention.

## System load

System chip shows CPU and RAM percentages; click or **Hyper+1** opens details.
Native `top`, `vm_stat`, `sysctl` and `memory_pressure -Q` refresh every ten seconds,
on wake and on opening. CPU uses the second one-second sample, not boot averages.
RAM used is active + wired + compressor pages; excludes reclaimable inactive pages.
Popup shows used/total RAM, compressed RAM, memory available from macOS pressure
accounting, swap used and 1/5/15-minute load averages (not CPU percentages).
Failed reads show unavailable values. No background network requests.

## Installation and updates

`install/macos/packages.sh` supplies SketchyBar, mise, jq, switchaudio-osx, fonts and AeroSpace.
Central mise config supplies Lua.
Apple's Xcode Command Line Tools supply clang and macOS frameworks (`xcode-select
--install` if missing); those cannot come from Homebrew. No official SbarLua
Homebrew formula exists. `run_onchange_before_30_install_sbarlua.sh.tmpl` installs
Homebrew package dependencies on existing machines too, installs Lua from source mise config
before deployment, compiles pinned SbarLua against mise Lua headers, validates loading, then atomically replaces
`~/.local/share/sketchybar_lua/sketchybar.so`. No bundled upstream Lua interpreter,
network access or builds during bar startup. Installer probes executable linking (including libm) before installing Lua and
passes the working SDK through `SDKROOT` to mise's Lua build. It falls back to an installed compatible SDK if Command Line Tools cannot read newer
SDK stubs. If no SDK works, update Command Line Tools or select matching Xcode;
do not modify SDK files. Homebrew service `sh.brew.sketchybar` owns bar startup and crash recovery;
AeroSpace sends events, not a second bar process.

After previewing `chezmoi diff`, run `chezmoi apply`, then
`brew services restart sketchybar` for an already-running bar. Lua config changes hot reload. Preview may
need network to resolve external icon mapping.

Changing central mise config triggers a rebuild with matching Lua headers on apply.
For a manual rebuild:

```sh
chezmoi execute-template < home/.chezmoiscripts/macos/run_onchange_before_30_install_sbarlua.sh.tmpl | sh
brew services restart sketchybar
```

Run from repository root. To upgrade SbarLua, update pinned revision in installer,
run checks, apply and restart. Installer reruns when its content, `install/macos/packages.sh`,
or central mise config changes; it does not rerun on unrelated `brew upgrade` operations.

## Native menu-bar blocking

SketchyBar uses normal layering (`topmost = false`). Following discussion
[#281](https://github.com/FelixKratz/SketchyBar/discussions/281), Homebrew
Hammerspoon runs a separate mouse-moved event tap. The managed module
`~/.hammerspoon/sketchybar_menu_guard.lua` caches display frames and clamps the
cursor below each display's top 4px. Hold Option to bypass; quitting Hammerspoon
also restores normal cursor behavior. Keyboard access to native menus remains.

Chezmoi manages `~/.hammerspoon/init.lua` directly. It loads keyboard and popup
controls, disables native login startup and hides Hammerspoon's menu icon.
Repository-managed KeepAlive LaunchAgents supervise Hammerspoon and AeroSpace
through LaunchServices; native login startup stays disabled. See
[desktop startup](../../.chezmoiscripts/.README.md#desktop-startup-on-macos).
macOS defaults script enables native menu-bar auto-hide. No separate Hammerspoon
setup script needed.
Grant Hammerspoon Accessibility permission in System Settings → Privacy &
Security (Device Control and Data Access on macOS 27), then reload its config.
This permission cannot be granted by dotfiles. Native menu-bar auto-hide must stay enabled. Event taps handle every
mouse move; keeping this outside SbarLua avoids blocking bar callbacks, but does
not eliminate event-tap overhead. No private macOS APIs or SIP changes used.

## Hyper key

`~/.hammerspoon/hyperkey.lua` uses native
`hidutil` to map Caps Lock to F18 while preserving other HID mappings, then
Hammerspoon maps held F18 to Command+Option+Control+Shift on keyboard events.
Tap Caps Lock for Escape. Caps+Return opens cmux,
Caps+B Firefox, Caps+C Visual Studio Code, Caps+O OpenCode. Vicinae owns app shortcuts
except Firefox: Hammerspoon waits for Caps Lock, B, and modifiers to release before
launching Firefox, avoiding Option-triggered Troubleshoot Mode.
Mapping reapplies on Hammerspoon launch, wake and USB connection.

Do not run another Caps Lock remapper alongside this module. Reload Hammerspoon
after deployment. Accessibility permission is required; Secure Input can prevent
event taps from working. If Hammerspoon is
stopped, Caps Lock remains F18 until mapping changes or reboot. Module affects
keyboard shortcuts, not mouse-click modifier flags.

## Checks

Use `luac -p` for Lua syntax checks without deployment or live app actions.
Do not add or generate dotfiles tests. Validate live font rendering, audio
permissions, multi-monitor layout and service login separately.
