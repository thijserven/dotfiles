#!/usr/bin/env bash

# Apply Bitwarden desktop settings.
# Bitwarden stores preferences in data.json (Electron) rather than NSUserDefaults,
# so jq is used instead of `defaults write`.

BW_DATA="$HOME/Library/Application Support/Bitwarden/data.json"

if [ ! -f "$BW_DATA" ]; then
  echo "Bitwarden data.json not found – skipping."
  return 0
fi

jq '
  .global_desktopSettings_browserIntegrationEnabled = true |
  .global_desktopSettings_browserIntegrationFingerprintEnabled = true |
  .global_desktopSettings_openAtLogin = false |
  .global_desktopSettings_sshAgentEnabled = true |
  .global_desktopSettings_trayEnabled = false
' "$BW_DATA" > "$BW_DATA.tmp" && mv "$BW_DATA.tmp" "$BW_DATA"

# Restart Bitwarden to pick up the new settings
if pgrep -xq "Bitwarden"; then
  killall Bitwarden
  sleep 1
  open -a Bitwarden
fi
