#!/bin/sh

set -eu

main() {
  if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
    printf '%s\n' 'Setup requires an Apple Silicon Mac.' >&2
    exit 1
  fi

  if [ "$(id -u)" -eq 0 ]; then
    printf '%s\n' 'Run setup as your normal administrator account, not with sudo.' >&2
    exit 1
  fi

  if ! /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
    sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  fi

  if [ ! -x /opt/homebrew/bin/brew ]; then
    # Homebrew installs missing Command Line Tools before Git is needed.
    installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
    /bin/bash -c "$installer"
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew install chezmoi
  chezmoi init --apply thijserven
}

main "$@"
