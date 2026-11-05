#!/usr/bin/env zsh

# Get unresolved PR review comments in Markdown for LLM consumption
# Usage: gh uc [--org ORGANIZATION]
#
# Defaults to 'thijserven', detects the repository name, and fetches open PRs
# matching the currently active Git branch in the local repository.

# Top-level configuration
ORGANIZATION="thijserven"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --org)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --org requires an organization name." >&2
        exit 1
      fi
      ORGANIZATION="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      echo "Usage: gh uc [--org ORGANIZATION]" >&2
      exit 1
      ;;
  esac
done

# 1. Detect repository name from current directory
repo=$(gh repo view --json name --jq '.name' 2>/dev/null)

if [ -z "$repo" ]; then
  echo "Error: No git repo found in this directory. Please execute this command in a valid git repo directory." >&2
  exit 1
fi

# 2. Get current active branch name
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

if [ -z "$current_branch" ]; then
  echo "Error: Could not determine current git branch (you may be in a detached HEAD state)." >&2
  exit 1
fi

# 3. Fetch open PRs matching the current branch
echo "Fetching open PRs for branch '$current_branch' in $ORGANIZATION/$repo..." >&2

open_prs=$(gh pr list --head "$current_branch" --json number,title --jq '.[] | "#\(.number)\t\(.title)"')

if [ -z "$open_prs" ]; then
  echo "Error: No open PRs found for the currently active branch '$current_branch'." >&2
  exit 1
fi

count=$(echo "$open_prs" | wc -l | tr -d ' ')

# 4. Auto-select single PR or present selection list for multiple PRs
if [ "$count" -eq 1 ]; then
  pr=$(echo "$open_prs" | awk '{print $1}' | tr -d '#')
  echo "Found 1 open PR (#$pr) for branch '$current_branch'. Selecting automatically..." >&2
else
  # Check if fzf is available for interactive selection
  if command -v fzf >/dev/null 2>&1; then
    selected=$(echo "$open_prs" | fzf --height=10 --layout=reverse --header="Multiple PRs found for '$current_branch'. Select one (Arrow keys + Enter):")
    pr=$(echo "$selected" | awk '{print $1}' | tr -d '#')
  else
    echo "Multiple PRs found for '$current_branch'. Select one using Arrow Keys and press Enter:" >&2
    selected_url=$(gh search prs --repo="$ORGANIZATION/$repo" --head="$current_branch" --state=open --json url,number,title --template '{{range .}}{{tablerow .number .title .url}}{{end}}' | gh pr view --web=false 2>/dev/tty)
    if [ -z "$selected_url" ]; then
      selected=$(echo "$open_prs" | fzf 2>/dev/null)
      pr=$(echo "$selected" | awk '{print $1}' | tr -d '#')
    fi
  fi
fi

if [ -z "$pr" ]; then
  echo "No PR selected. Exiting." >&2
  exit 1
fi

# 5. Fetch unresolved comments
gh api graphql \
  -F owner="$ORGANIZATION" \
  -F repo="$repo" \
  -F pr="$pr" \
  -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            path
            line
            comments(first: 10) {
              nodes {
                author { login }
                body
              }
            }
          }
        }
      }
    }
  }
' --jq '.data.repository.pullRequest.reviewThreads.nodes
    | map(select(.isResolved == false))
    | .[]
    | "### File: " + .path + " (Line " + (.line // "N/A" | tostring) + ")\n**Author:** " + .comments.nodes[0].author.login + "\n**Comment:** " + (.comments.nodes | map(.author.login + ": " + .body) | join("\n\n")) + "\n---"'
