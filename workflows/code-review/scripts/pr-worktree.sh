#!/usr/bin/env bash
# A throwaway, detached worktree per reviewed PR, so reviews never switch or
# reset the shared clone under $GREYBEARD_DATA/sources/{repo} and two reviews
# can run at once.
#
# Usage: pr-worktree.sh add <repo> <branch> [pr-number]   prints the worktree path
#        pr-worktree.sh remove <repo> <pr-number | branch>
#
# `add` needs origin/<branch> fetched already. It makes no network calls, so it
# runs inside the sandbox; the fetch is a separate, standalone command.
set -euo pipefail

cmd="${1:?add or remove}"
repo="${2:?repo}"
target="${3:?branch or pr number}"
clone="${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/$repo"

worktree_path() {
  local suffix="$1"
  case "$suffix" in
    ''|*[!0-9]*) suffix="$(printf '%s' "$suffix" | tr '/' '-')" ;;
    *) suffix="pr$suffix" ;;
  esac
  printf '%s/%s-%s' "$(dirname "$clone")" "$repo" "$suffix"
}

case "$cmd" in
  add)
    branch="$target"
    path="$(worktree_path "${4:-$branch}")"
    if ! git -C "$clone" rev-parse --verify -q "refs/remotes/origin/$branch" >/dev/null; then
      echo "origin/$branch is not fetched. Run, as its own command outside the sandbox:" >&2
      echo "  git -C $clone fetch origin main $branch" >&2
      exit 1
    fi
    if [ -d "$path" ]; then
      git -C "$path" checkout -q --detach "origin/$branch"
    else
      git -C "$clone" worktree prune
      git -C "$clone" worktree add -q --detach "$path" "origin/$branch"
    fi
    echo "$path"
    ;;
  remove)
    path="$(worktree_path "$target")"
    [ -d "$path" ] || { git -C "$clone" worktree prune; exit 0; }
    git -C "$clone" worktree remove --force "$path"
    ;;
  *)
    echo "usage: pr-worktree.sh add <repo> <branch> [pr] | remove <repo> <pr|branch>" >&2
    exit 2
    ;;
esac
