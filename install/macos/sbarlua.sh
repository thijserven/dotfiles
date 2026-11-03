#!/bin/sh

# Build pinned SbarLua against mise Lua and a compatible macOS SDK.
set -eu

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Pin source, link against mise Lua instead of upstream's bundled Lua ABI.
revision=dba9cc421b868c918d5c23c408544a28aadf2f2f

# Before deployment, use source config so headers match the runtime being deployed.
export MISE_CONFIG_FILE="$DOTFILES_ROOT/home/private_dot_config/mise/config.toml"

install_dependencies() {
  # Package changes must install dependencies on existing machines too.
  sh "$DOTFILES_ROOT/install/macos/packages.sh"

  if ! xcrun --find clang >/dev/null 2>&1; then
    echo 'SbarLua requires Xcode Command Line Tools: run xcode-select --install, then retry.' >&2
    exit 1
  fi
}

select_sdk() {
  # SDK updates can outpace Apple's installed linker. Probe before downloading/building.
  default_sdk="$(xcrun --sdk macosx --show-sdk-path)"
  sdk_root="$(dirname "$default_sdk")"
  sdk=""
  os_major="$(sw_vers -productVersion | cut -d. -f1)"

  for candidate in "$default_sdk" "$sdk_root/MacOSX$os_major.sdk" "$sdk_root"/MacOSX*.sdk; do
    if printf 'int main(void) { return 0; }\n' | xcrun clang -isysroot "$candidate" \
      -framework CoreFoundation -lm -x c - -o "$build_dir/probe" \
      >"$build_dir/probe.log" 2>&1; then
      sdk="$candidate"
      break
    fi
  done

  if [ -z "$sdk" ]; then
    cat "$build_dir/probe.log" >&2
    echo 'No installed macOS SDK works with selected linker. Update Command Line Tools or select matching Xcode with xcode-select, then retry.' >&2
    exit 1
  fi

  printf 'SbarLua SDK: %s\n' "$sdk"
}

build_module() {
  curl --fail --location --retry 3 "https://github.com/FelixKratz/SbarLua/archive/$revision.tar.gz" -o "$build_dir/source.tar.gz"
  tar -xzf "$build_dir/source.tar.gz" -C "$build_dir" --strip-components=1

  lua_prefix="$(mise -C "$DOTFILES_ROOT/home/private_dot_config/mise" where lua)"
  xcrun clang -std=c99 -O3 -shared -fPIC -undefined dynamic_lookup -isysroot "$sdk" \
    -I"$lua_prefix/include" -framework CoreFoundation \
    "$build_dir/src/sketchybar.c" "$build_dir/src/parsing.c" "$build_dir/src/cJSON.c" \
    -o "$build_dir/sketchybar.so"

  # Validate before replacing any working module.
  "$lua_prefix/bin/lua" -e "package.cpath = '$build_dir/?.so;' .. package.cpath; assert(require('sketchybar'))"
}

install_module() {
  install_dir="$HOME/.local/share/sketchybar_lua"

  mkdir -p "$install_dir"
  install -m 755 "$build_dir/sketchybar.so" "$install_dir/sketchybar.so.new"
  mv -f "$install_dir/sketchybar.so.new" "$install_dir/sketchybar.so"
}

main() {
  install_dependencies

  build_dir="$(mktemp -d "${TMPDIR:-/tmp}/sbarlua.XXXXXX")"
  trap 'rm -rf "$build_dir"' EXIT HUP INT TERM

  select_sdk
  SDKROOT="$sdk" mise -C "$DOTFILES_ROOT/home/private_dot_config/mise" install lua
  build_module
  install_module
}

main "$@"
