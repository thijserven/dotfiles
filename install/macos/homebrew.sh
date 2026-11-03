#!/bin/sh

# Install Homebrew if not present (normally prepared by the age bootstrap hook).
set -eu

load_homebrew() {
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      break
    fi
  done
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

main() {
  load_homebrew
  install_homebrew
}

main "$@"
