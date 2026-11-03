#!/usr/bin/env zsh

# git rb "message" - squash all branch commits into one and force-push.
find_source_branch() {
  local branch="$1"
  local source upstream origin_head

  # Prefer branch creation history, then upstream, origin/HEAD, and develop.
  source=$(git reflog show --format=%gs "$branch" 2>/dev/null | sed -n 's/^branch: Created from //p' | head -n1)
  if [ "$source" = "HEAD" ] || [ "$source" = "$branch" ]; then
    source=''
  fi

  if [ -z "$source" ]; then
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)
    upstream=${upstream#origin/}

    if [ "$upstream" != "$branch" ]; then
      source=$upstream
    fi
  fi

  if [ -z "$source" ]; then
    origin_head=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    origin_head=${origin_head#origin/}

    if [ "$origin_head" != "$branch" ]; then
      source=$origin_head
    fi
  fi

  printf '%s\n' "${source:-develop}"
}

main() {
  local message="$1"
  local branch source merge_base

  if [ -z "$message" ]; then
    echo 'usage: git rb "commit message"' >&2
    exit 2
  fi

  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    echo "not on a branch" >&2
    exit 2
  fi

  source=$(find_source_branch "$branch")
  merge_base=$(git merge-base "$source" HEAD) || return
  git reset --soft "$merge_base" || return

  if git diff --cached --quiet; then
    echo "nothing to commit after reset from $source" >&2
    exit 1
  fi

  git commit -m "$message" && git push --force-with-lease origin "$branch"
}

main "$@"
