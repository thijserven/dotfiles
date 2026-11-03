#!/usr/bin/env bash

# Start managed services and supervise essential apps through LaunchServices.
set -eu

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

start_services() {
  domain="gui/$(id -u)"

  # Homebrew's formulas provide login startup and KeepAlive crash recovery.
  for service in borders sketchybar; do
    launchctl enable "${domain}/sh.brew.${service}"
    brew services start "$service"
  done
}

start_apps() {
  for app in aerospace hammerspoon vicinae; do
    label="local.keepalive.${app}"
    agent="$HOME/Library/LaunchAgents/${label}.plist"
    launchctl enable "${domain}/${label}"

    # Reapplying must not replace a live waiter or launch a second instance.
    if ! launchctl print "${domain}/${label}" >/dev/null 2>&1; then
      launchctl bootstrap "$domain" "$agent"
    fi
  done

  # Unlike the apps above, OrbStack should only be started once after bootstrap so
  # it can initialize docker.
  open -a OrbStack
}

main() {
  start_services
  start_apps
}

main "$@"
