#!/bin/sh

# Install macOS packages and casks.
set -eu

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"

load_homebrew() {
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      break
    fi
  done
}

install_packages() {
  brew bundle --file="$DOTFILES_ROOT/install/macos/packages.txt"
}

main() {
  load_homebrew
  install_packages
}

main "$@"
