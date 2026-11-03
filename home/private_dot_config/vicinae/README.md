# Vicinae

macOS launcher configuration and bootstrap list for Raycast extension bundles. Excluded from Linux deployment.

## Files

| Source                                                                                                       | Role                                                                                                   |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| [settings.json](settings.json)                                                                               | `~/.config/vicinae/settings.json`; launcher preferences                                                |
| [extensions.txt](extensions.txt)                                                                             | Raycast Extensions Store IDs for regular store extensions; bootstrap-only and excluded from deployment |
| [extensions/](extensions/)                                                                                   | Custom local extensions maintained for this repository                                                 |
| [keybindings.json](keybindings.json)                                                                         | Additional custom keybindings not detected automatically                                               |
| [Extension installer](../../.chezmoiscripts/macos/run_onchange_before_40_install_vicinae_extensions.sh.tmpl) | Installs missing Raycast store bundles before configuration deployment                                 |

Settings use `Control+Space`, Catppuccin Macchiato dark theme, system font, no tray icon, close on focus loss, and Escape to close. System-information telemetry is disabled. Vicinae may rewrite this file after GUI changes, losing comments and formatting; reconcile intentional GUI changes with source before deployment.

## Hyper app shortcuts

Hammerspoon maps held Caps Lock to Hyper; Vicinae owns app launching through `providers.applications.entrypoints` in `settings.json` for Hyper+Return (cmux), Hyper+C (VS Code), and Hyper+O (OpenCode). Hammerspoon owns Hyper+B (Firefox), waiting until Caps Lock, B, and modifiers release to avoid Firefox's Option-triggered Troubleshoot Mode. Do not also bind Firefox in Vicinae. Hyper uses `super+control+alt+shift` (both Command and Control on macOS). OpenCode's Vicinae entrypoint is `ai.opencode`, not its full bundle ID `ai.opencode.desktop`.

Hyper+K opens **Browse Keybindings** directly, including when Vicinae's window is hidden, through `@thijserven/keybindings` → `browse`.

Vicinae must be running with global-shortcut permissions. Keybindings extension lists these shortcuts as custom entries in `keybindings.json`; update them manually when settings change. Firefox's release binding is the only app-launch exception in Hammerspoon.

## Extensions

Add regular extensions from the Raycast Extensions Store as `author/name` pairs in `extensions.txt`, one per line. Custom local extensions made for this repository live under [extensions/](extensions/). Blank lines and `#` comments are allowed. Current store IDs: `doist/todoist`, `gebeto/translate`, `HelloImSteven/sips`, `rolandleth/kill-process`, `thomas/color-picker`, and `thomas/visual-studio-code`.

List content is embedded in installer, so edits change its `run_onchange` hash. Next requested `chezmoi apply` installs missing bundles under `~/.local/share/vicinae/extensions/store.raycast.<name>`. Existing paths are skipped: no updates, repairs, or removal. Removing a list entry does not uninstall its bundle. Extension preferences remain in `~/.config/vicinae/settings.json`.

Installer requires system Python 3 from Apple Command Line Tools and `curl`. Downloads use Raycast's internal metadata API and signed bundle URLs. Installer validates metadata, archive paths, and manifest identity, stages extraction, then publishes each bundle. Internal API/layout changes can break bootstrap.

Installer implementation lives in [`install/macos/vicinae_extensions.sh`](../../../install/macos/vicinae_extensions.sh); shell entry point retains Python for archive validation and extraction.

## Keybindings

Vendored [Keybindings](../../../vendor/keybindings/README.md), a modified version of [Raycast Shortcut Library](https://github.com/raycast/extensions/tree/ff678517a421538e8533030aa447420631886169/extensions/shortcut-library), is built and installed automatically by `run_onchange_after_45_install_keybindings.sh.tmpl` on macOS after configuration deployment, before desktop-service startup. Source and lockfile hashes trigger rebuilds. Uses the central mise Node.js LTS default and locked npm dependencies; Vicinae itself must already be installed.

On first open, **Browse Keybindings** reads `~/.config/vicinae/keybindings.json` and detects deployed AeroSpace bindings. Vicinae shortcuts are ordinary custom entries without `source` or `id`, maintained manually; the toggle display remains `cmd + space`. Use `source: "aerospace"` with ID formatted as `mode.key` (for example, `main.alt-h`) to override detected AeroSpace bindings. Overrides replace title and keys; optional `category` and `tags` can also be set. Read-only, no store-bundle patches. Explicit preference overrides are preserved.

## Empty Trash

Search **Empty Trash** to run [`empty_trash.sh`](../../private_dot_local/share/vicinae/scripts/executable_empty_trash.sh), deployed to `~/.local/share/vicinae/scripts/empty_trash.sh`. Finder permanently deletes Trash contents immediately, without confirmation. This cannot be undone. macOS may request permission for Vicinae to control Finder under **System Settings → Privacy & Security → Automation**. Finder errors remain visible in Vicinae.

After deployment, run **Reload Script Directories** in Vicinae if the command is not listed yet. No extension or extra dependency is required.

## Startup

Repository-managed [LaunchAgent](../../.chezmoiscripts/.README.md#desktop-startup-on-macos) owns startup and automatic recovery after quit/crash. Keep native **Launch at Login** off; this native login item is not controlled by the repository.

Supervision uses `open -W -a Vicinae`, never the app binary or `open -n`. LaunchServices reuses an existing instance; competing binary instances can terminate the shared extension manager. Stop supervision before quitting for maintenance.

Launch manually through Launch Services:

```sh
open -a Vicinae
```

`KeepAlive` covers normal quits and crashes; restart is event-driven with a one-second rapid-retry throttle, not a zero-downtime guarantee. [Borders](../borders/README.md) excludes Vicinae from window outlines.

[Application index](../README.md)
