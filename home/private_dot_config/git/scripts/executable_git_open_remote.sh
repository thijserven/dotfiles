#!/usr/bin/env zsh

# git o "path" - open the remote page of the repo in the browser.
remote_page() {
  local remote_url repo_url
  remote_url=$(git remote get-url origin 2>/dev/null)
  repo_url=${remote_url%.git}

  if [[ "$repo_url" == git@*:* ]]; then
    repo_url=${repo_url#git@}
    repo_url="https://${repo_url%%:*}/${repo_url#*:}"
  elif [[ "$repo_url" == ssh://git@* ]]; then
    repo_url="https://${repo_url#ssh://git@}"
  fi

  printf '%s\n' "$repo_url"
}

main() {
  local repo_url
  repo_url=$(remote_page)

  if [[ -z "$repo_url" ]]; then
    echo "No remote found"
    exit 1
  fi

  open "$repo_url/$1"
}

main "$@"
