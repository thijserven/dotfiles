#!/usr/bin/env zsh

# git p - push with auto --set-upstream for new branches.
main() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)

  if [ -n "$branch" ] && ! git rev-parse --abbrev-ref "${branch}@{upstream}" >/dev/null 2>&1; then
    exec git push --set-upstream origin "$branch" "$@"
  fi

  exec git push "$@"
}

main "$@"
