#!/bin/bash

set -e

main() {
    # Set zsh as default shell if not already.
    if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]; then
        echo "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
    fi
}

main "$@"
