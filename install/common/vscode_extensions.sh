#!/usr/bin/env bash

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"
SOURCE="$DOTFILES_ROOT/home/.chezmoitemplates/vscode/extensions.txt"

# Suppress Node.js deprecation warnings from VS Code CLI.
export NODE_NO_WARNINGS=1

resolve_code_cli() {
    if command -v code >/dev/null 2>&1; then
        CODE="$(command -v code)"
    elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
        CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    elif [[ -x "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
        CODE="$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    else
        echo "VS Code CLI not found. Skipping extensions."
        exit 0
    fi
}

install_extensions() {
    # Get installed extensions once.
    INSTALLED="$("$CODE" --list-extensions)"

    while IFS= read -r extension || [[ -n "$extension" ]]; do
        # Remove Windows-style line endings and surrounding whitespace.
        extension="${extension%$'\r'}"
        extension="${extension#"${extension%%[![:space:]]*}"}"
        extension="${extension%"${extension##*[![:space:]]}"}"

        # Skip empty lines and comments.
        [[ -z "$extension" || "$extension" == \#* ]] && continue

        # Skip already installed extensions (case-insensitive).
        if printf '%s\n' "$INSTALLED" | grep -Fxiq -- "$extension"; then
            echo "  ✓ $extension"
            continue
        fi

        echo "  + Installing $extension"
        "$CODE" --install-extension "$extension"
    done < "$SOURCE"
}

main() {
    resolve_code_cli

    if [[ ! -f "$SOURCE" ]]; then
        echo "VS Code extensions file not found: $SOURCE" >&2
        exit 1
    fi

    echo "Installing VS Code extensions..."
    install_extensions
    echo "VS Code extensions are configured."
}

main
