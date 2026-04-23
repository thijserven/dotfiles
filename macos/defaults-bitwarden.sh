#!/usr/bin/env bash

# Apply Bitwarden desktop settings from tracked config.
# Bitwarden stores preferences in data.json (Electron) rather than NSUserDefaults,
# but the live file also contains account/runtime state. Only managed keys from the
# dotfiles config are merged into the live file.

BW_DATA="$HOME/Library/Application Support/Bitwarden/data.json"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BW_MANAGED_CONFIG="$XDG_CONFIG_HOME/bitwarden/data.json"

if [ ! -f "$BW_MANAGED_CONFIG" ] && [ -n "${DOTFILES_DIR:-}" ]; then
  BW_MANAGED_CONFIG="$DOTFILES_DIR/config/bitwarden/data.json"
fi

if [ ! -f "$BW_MANAGED_CONFIG" ]; then
  echo "Bitwarden managed config not found – skipping."
  return 0
fi

if [ ! -f "$BW_DATA" ]; then
  echo "Bitwarden data.json not found – skipping."
  return 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to apply Bitwarden settings."
  return 1
fi

jq --slurpfile managed "$BW_MANAGED_CONFIG" '
  ($managed[0] // {}) as $managed
  | reduce (($managed.exact // {}) | to_entries[]) as $item (.;
      .[$item.key] = $item.value
    )
  | reduce (($managed.suffix // {}) | to_entries[]) as $item (.;
      with_entries(
        if (.key | endswith($item.key)) then .value = $item.value else . end
      )
    )
' "$BW_DATA" > "$BW_DATA.tmp" && mv "$BW_DATA.tmp" "$BW_DATA"

# Restart Bitwarden to pick up the new settings
if pgrep -xq "Bitwarden"; then
  killall Bitwarden
  sleep 1
  open -a Bitwarden
fi
