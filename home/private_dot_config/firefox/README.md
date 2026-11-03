# Firefox

Enterprise policies for browser defaults, privacy, and extensions.

## Files

- [policies.json](policies.json): installs Bitwarden, uBlock Origin, and Catppuccin Macchiato Mauve theme using `normal_installed`; disables built-in password saving, autofill, telemetry, studies, sponsored content, and suggestions. Adds GitHub bookmark and session-restore default.
- [Policy installer](../../.chezmoiscripts/macos/run_onchange_after_41_firefox_policy.sh.tmpl): validates JSON and installs system-level policies whenever policy content changes.

## Operations

`~/.config/firefox/policies.json` is a managed copy, not Firefox's policy-loading location. Installer uses:

| Platform | Active policy location |
| --- | --- |
| macOS | `/Library/Preferences/org.mozilla.firefox.plist`, imported with `sudo defaults import` |
| Linux | `/etc/firefox/policies/policies.json` |

Policy deployment requires administrator access. If Firefox was running, the installer asks it to quit and reopens it only after shutdown; otherwise it leaves Firefox closed. Save active work before deploying policy changes.

Inspect `about:policies` after deployment for active policies and errors. Some preferences are defaults rather than locks; `GenerativeAI.Enabled` is false but `Locked` is false.

[Application index](../README.md)
