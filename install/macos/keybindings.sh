#!/bin/bash

# Build, test, and install the local Vicinae keybindings extension.
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

prepare_node() {
  # Use central runtime defaults, noninteractive scripts do not load shell init.
  mise -C "${XDG_CONFIG_HOME:-$HOME/.config}/mise" install node
  eval "$(mise -C "${XDG_CONFIG_HOME:-$HOME/.config}/mise" env --shell bash)"
}

install_extension() {
  npm ci --no-audit --no-fund
  npm test
  npm run build

  # Native CLI installs compiled bundle under Vicinae's extension directory.
  ./node_modules/.bin/vici build
}

main() {
  cd "$DOTFILES_ROOT/vendor/keybindings"

  prepare_node
  install_extension
}

main "$@"
