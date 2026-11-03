#!/usr/bin/env bash

# Set browser and editor defaults where macOS permits changes.
set -euo pipefail

set_default_apps() {
  # macOS may reject protected handlers or prompt in System Settings; quiet skips noisy no-op reports.
  dutix set Firefox --schemes http --yes --quiet || true

  # Use registered extensions only; dynamic UTIs cannot be assigned by dutix.
  dutix set Code --extensions txt,md,json,yaml,yml,js,ts,mjs,py,rb,java,c,cpp,h,hpp,html,css,sh,zsh,bash,pl,php,swift,xml,svg,log,csv,diff,patch --yes --quiet || true

  # Cmux terminal default is configured through its Settings > General > Default Terminal control.
}

main() {
  command -v dutix >/dev/null 2>&1 || exit 0

  set_default_apps
}

main "$@"
