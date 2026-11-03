#!/bin/sh

# Clone configured specifai-net repositories over SSH.
set -eu

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"

main() {
  repos_file="$DOTFILES_ROOT/install/macos/repos.txt"
  developer_dir="$HOME/Developer"

  if [ ! -r "$repos_file" ]; then
    printf 'Cannot read repository list: %s\n' "$repos_file" >&2
    exit 1
  fi

  mkdir -p "$developer_dir"

  while IFS= read -r line || [ -n "$line" ]; do
    repo=$(printf '%s\n' "$line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$repo" ] || continue

    case "$repo" in
      .|..|*[!a-zA-Z0-9._-]*)
        printf 'Invalid repository name: %s\n' "$repo" >&2
        exit 1
        ;;
    esac

    target="$developer_dir/$repo"
    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ -d "$target/.git" ] || [ -f "$target/.git" ]; then
        printf 'Skipping existing checkout: %s\n' "$target"
        continue
      fi

      printf 'Destination exists but is not a Git checkout: %s\n' "$target" >&2
      exit 1
    fi

    git clone -- "git@github.com:thijserven/$repo.git" "$target"
  done < "$repos_file"
}

main "$@"
