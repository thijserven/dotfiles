#!/usr/bin/env bash

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"

# Re-run whenever policies.json changes.
SOURCE="$DOTFILES_ROOT/home/private_dot_config/firefox/policies.json"

detect_running_firefox() {
    FIREFOX_WAS_RUNNING=false

    if pgrep -x "firefox" >/dev/null 2>&1; then
        FIREFOX_WAS_RUNNING=true
    fi
}

validate_source() {
    if [[ ! -f "$SOURCE" ]]; then
        echo "Firefox policies not found: $SOURCE" >&2
        exit 1
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "$SOURCE" >/dev/null
    elif command -v jq >/dev/null 2>&1; then
        jq empty "$SOURCE"
    else
        echo "Error: Install Python 3 or jq for JSON validation." >&2
        exit 1
    fi
}

install_policies() {
    echo "Installing Firefox policies for macOS..."

    if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: Python 3 is required on macOS." >&2
        exit 1
    fi

    PLIST_DOMAIN="/Library/Preferences/org.mozilla.firefox"

    TEMP_PLIST="$(mktemp "${TMPDIR:-/tmp}/firefox-policies.XXXXXX")"
    trap 'rm -f "$TEMP_PLIST"' EXIT

    python3 - "$SOURCE" "$TEMP_PLIST" <<'PY'
import json
import plistlib
import sys

source, destination = sys.argv[1:3]

with open(source, "r", encoding="utf-8") as f:
    data = json.load(f)

policies = data.get("policies")

if not isinstance(policies, dict):
    raise ValueError("Missing or invalid 'policies' object")

plist = {
    **policies,
    "EnterprisePoliciesEnabled": True,
}

with open(destination, "wb") as f:
    plistlib.dump(plist, f, sort_keys=True)
PY
    plutil -lint "$TEMP_PLIST"

    sudo defaults import "$PLIST_DOMAIN" "$TEMP_PLIST"

    echo "Firefox macOS policies installed."
}

restart_firefox_if_running() {
    if [[ "$FIREFOX_WAS_RUNNING" == true ]]; then
        echo "Firefox is running. Restarting to apply policies..."

        # Gracefully quit Firefox (preserves session).
        osascript -e 'tell application id "org.mozilla.firefox" to quit'

        # Wait for Firefox to exit (maximum 15 seconds).
        for ((i=0; i<30; i++)); do
            if ! pgrep -x "firefox" >/dev/null 2>&1; then
                break
            fi
            sleep 0.5
        done

        # Reopen only if Firefox actually stopped.
        if ! pgrep -x "firefox" >/dev/null 2>&1; then
            open -a Firefox
            echo "Firefox restarted."
        else
            echo "Warning: Firefox did not close. Restart manually." >&2
        fi

    else
        echo "Firefox was not running. Leaving it closed."
    fi
}

main() {
    detect_running_firefox
    validate_source
    install_policies
    restart_firefox_if_running

    echo "Firefox policies applied. Verify at about:policies."
}

main "$@"
