#!/bin/sh
set -eu

validate_directory() {
  # Only accept private mktemp directories, never arbitrary cleanup targets.
  case "$dir" in
    */../*|*/./*)
      exit 1
      ;;
    /*/sketchybar-speedtest.*)
      ;;
    *)
      exit 1
      ;;
  esac

  case "${dir##*/}" in
    *[!a-zA-Z0-9.-]*)
      exit 1
      ;;
    sketchybar-speedtest.?*)
      ;;
    *)
      exit 1
      ;;
  esac

  [ ! -L "$dir" ] || exit 1
}

cancel() {
  # Completion may remove the directory before cancellation arrives.
  [ -d "$dir" ] || return 0
  touch "$dir/cancel" 2>/dev/null || return 0
  [ -f "$dir/pid" ] || return 0
  read -r pid < "$dir/pid" || return 0
  case "$pid" in
    *[!0-9]*|''|0*|1)
      return 1
      ;;
  esac
  kill "$pid" 2>/dev/null || :
}

run() {
  [ -d "$dir" ] || return 1
  trap 'rm -rf -- "$dir"' EXIT
  [ ! -e "$dir/cancel" ] || exit 130
  # User requested noninteractive acceptance of Ookla's license/privacy terms.
  speedtest --accept-license --accept-gdpr --format=json --progress=yes \
    --progress-update-interval=1000 > "$dir/progress" &
  pid=$!
  printf '%s\n' "$pid" > "$dir/pid"
  # Cancellation may arrive before PID is published.
  if [ -e "$dir/cancel" ]; then
    kill "$pid" 2>/dev/null || :
  fi
  wait "$pid"
  tail -n 1 "$dir/progress"
}

main() {
  [ "$#" -eq 2 ] || exit 1
  mode=$1
  dir=$2
  validate_directory

  case "$mode" in
    run)
      run
      ;;
    cancel)
      cancel
      ;;
    progress)
      tail -n 1 "$dir/progress" 2>/dev/null || :
      ;;
    *)
      exit 1
      ;;
  esac
}

main "$@"
