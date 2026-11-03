#!/bin/sh

# Runs before chezmoi reads encrypted files, not as a run_before script.
set -eu

server=$1
note=$2
identity=$3
recipient=$4
chezmoi=$5

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

check_identity_path() {
  if [ -L "$identity" ]; then
    fail "Refusing symlink identity: $identity"
  fi

  if [ -f "$identity" ]; then
    chmod 600 "$identity"
    [ "$(find "$identity" -prune -perm 600 -print)" = "$identity" ] || fail "Cannot secure $identity"
    exit 0
  fi

  [ ! -e "$identity" ] || fail "Identity path is not a regular file: $identity"
}

cleanup() {
  rm -rf "$work"
  if [ -n "${key_tmp:-}" ]; then
    rm -f "$key_tmp"
  fi
  unset BW_SESSION
}

ensure_dependencies() {
  case "$(uname -s)" in
    Darwin)
      # Fresh shells do not yet have Homebrew on PATH.
      for prefix in /opt/homebrew /usr/local; do
        if [ -x "$prefix/bin/brew" ]; then
          eval "$("$prefix/bin/brew" shellenv)"
          break
        fi
      done

      if ! command -v brew >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$work/install-homebrew.sh"
        /bin/bash "$work/install-homebrew.sh"
        case "$(uname -m)" in
          arm64) eval "$(/opt/homebrew/bin/brew shellenv)" ;;
          *) eval "$(/usr/local/bin/brew shellenv)" ;;
        esac
      fi

      if ! command -v bw >/dev/null 2>&1; then
        brew install bitwarden-cli
      fi
      if ! command -v jq >/dev/null 2>&1; then
        brew install jq
      fi
      ;;
    Linux)
      PATH="$HOME/.local/bin:$PATH"
      export PATH

      if ! command -v bw >/dev/null 2>&1; then
        # ponytail: pinned official binaries for x86_64/arm64; update version and hashes together.
        version=2026.10.0
        case "$(uname -m)" in
          x86_64|amd64)
            archive="bw-linux-$version.zip"
            checksum=269b67559caab860d1737f7554b32bdb8be9285d5689fee55193c137a0df9973
            ;;
          aarch64|arm64)
            archive="bw-linux-arm64-$version.zip"
            checksum=2fe9d8a18dc4c35ea2f9e3e42a4021f14f129ef47e80b6cea1e3b34176f1583a
            ;;
          *) fail 'Automatic Bitwarden installation supports Linux x86_64 and arm64 only. Install bw manually.' ;;
        esac

        for tool in curl unzip sha256sum; do
          command -v "$tool" >/dev/null 2>&1 || fail "Install $tool before bootstrapping."
        done

        curl -fsSL "https://github.com/bitwarden/clients/releases/download/cli-v$version/$archive" -o "$work/$archive"
        printf '%s  %s\n' "$checksum" "$work/$archive" | sha256sum -c - >/dev/null
        unzip -q "$work/$archive" bw -d "$work"
        mkdir -p "$HOME/.local/bin"
        install -m 755 "$work/bw" "$HOME/.local/bin/bw"
      fi

      if ! command -v jq >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
          sudo apt-get update
          sudo apt-get install -y jq
        elif command -v pacman >/dev/null 2>&1; then
          sudo pacman -S --noconfirm --needed jq
        else
          fail 'Install jq before bootstrapping on this Linux distribution.'
        fi
      fi
      ;;
    *) fail 'Bitwarden bootstrap supports macOS and Linux only.' ;;
  esac
}

unlock_vault() {
  status=$(bw status)
  state=$(printf '%s' "$status" | jq -er '.status')
  current_server=$(printf '%s' "$status" | jq -r '.serverUrl // "https://vault.bitwarden.com"')

  if [ "${current_server%/}" != "${server%/}" ]; then
    [ "$state" = unauthenticated ] || fail "Bitwarden is logged in to $current_server. Log out manually before switching to $server."
    bw config server "$server" >/dev/null
  fi

  case "$state" in
    unauthenticated)
      printf 'Sign in with the Bitwarden account that contains the %s secure note.\n' "$note" >&2
      BW_SESSION=$(bw login --raw)
      export BW_SESSION
      ;;
    locked)
      printf 'Unlock the Bitwarden account that contains the %s secure note.\n' "$note" >&2
      BW_SESSION=$(bw unlock --raw)
      export BW_SESSION
      ;;
    unlocked) ;;
    *) fail "Unexpected Bitwarden status: $state" ;;
  esac

  bw sync >/dev/null
}

restore_identity() {
  # Avoid a pipeline hiding a failed bw command; vault output stays private.
  bw list items --search "$note" > "$work/items.json"
  id=$(jq -er --arg name "$note" '
    [.[] | select(.name == $name and .type == 2 and .deletedDate == null)]
    | if length == 1 then .[0].id else error("Expected exactly one matching secure note") end
  ' "$work/items.json")

  mkdir -p "$(dirname "$identity")"
  key_tmp=$(mktemp "$(dirname "$identity")/.age-key.XXXXXX")
  bw get notes "$id" > "$key_tmp"

  # Suppress parser diagnostics: malformed input could include private key text.
  actual_recipient=$("$chezmoi" age-keygen -y "$key_tmp" 2>/dev/null) || fail 'Bitwarden note does not contain a valid age identity.'
  [ "$actual_recipient" = "$recipient" ] || fail 'Bitwarden age identity does not match configured public recipient.'
  chmod 600 "$key_tmp"
  [ "$(find "$key_tmp" -prune -perm 600 -print)" = "$key_tmp" ] || fail 'Cannot secure age identity.'

  # Hard link publishes the complete file automically, without replacing an existing identity.
  ln "$key_tmp" "$identity"
  printf 'Age identity restored to %s (mode 600).\n' "$identity" >&2
}

main() {
  check_identity_path

  case "$server" in
    https://?*) ;;
    *) fail 'Bitwarden vault URL must start with https://' ;;
  esac

  umask 077
  work=$(mktemp -d)
  trap cleanup EXIT
  trap 'exit 1' HUP INT TERM

  ensure_dependencies
  unlock_vault
  restore_identity
}

main
