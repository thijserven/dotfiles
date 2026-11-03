#!/usr/bin/env bash

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"

# Re-run whenever policies.json changes.
SOURCE="$DOTFILES_ROOT/home/private_dot_config/firefox/policies.json"

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
    DEST="/etc/firefox/policies"
    POLICY_FILE="$DEST/policies.json"

    echo "Installing Firefox policies for Linux..."

    if [[ -f "$POLICY_FILE" ]] && cmp -s "$SOURCE" "$POLICY_FILE"; then
        echo "Firefox policies are already up to date."
        exit 0
    fi

    if [[ "$EUID" -eq 0 ]]; then
        mkdir -p "$DEST"
        install -m 644 "$SOURCE" "$POLICY_FILE"
    else
        sudo mkdir -p "$DEST"
        sudo install -m 644 "$SOURCE" "$POLICY_FILE"
    fi

    echo "Firefox Linux policies installed."
}

restart_firefox() {
    if [[ "$FIREFOX_WAS_RUNNING" == true ]]; then
        echo "Firefox is running. Restarting to apply policies..."

        # SIGTERM lets Firefox shut down gracefully.
        pkill -TERM -u "$(id -u)" -x firefox || true

        # Wait for Firefox to exit (maximum 15 seconds).
        for ((i=0; i<30; i++)); do
            if ! pgrep -u "$(id -u)" -x firefox >/dev/null 2>&1; then
                break
            fi
            sleep 0.5
        done

        # Reopen only after Firefox has exited.
        if ! pgrep -u "$(id -u)" -x firefox >/dev/null 2>&1; then
            nohup firefox >/dev/null 2>&1 </dev/null &
            echo "Firefox restarted."
        else
            echo "Warning: Firefox did not close. Restart manually." >&2
        fi
    else
        echo "Firefox was not running. Leaving it closed."
    fi
}

main() {
    FIREFOX_WAS_RUNNING=false
    if pgrep -u "$(id -u)" -x "firefox" >/dev/null 2>&1; then
        FIREFOX_WAS_RUNNING=true
    fi

    validate_source
    install_policies
    restart_firefox

    echo "Firefox policies applied. Verify at about:policies."
}

main "$@"
