#!/usr/bin/env bash
# Compares HEAD to the newest SHA any code-review run record holds for a branch.
#
# Usage: last-reviewed-sha.sh <repo> <branch> [head-sha]
#   Run from inside the target repo checkout when head-sha is omitted.
#
# Exit 0: HEAD is the last reviewed SHA, or has the same branch diff (a clean rebase).
# Exit 1: HEAD is not the last reviewed SHA. Run `review --fix` before pushing.
# Exit 2: no record for this branch in runs/ or fix-runs/.
set -euo pipefail

repo="${1:?repo}"
branch="${2:?branch}"
head="${3:-$(git rev-parse HEAD)}"
data="${GREYBEARD_DATA:-$HOME/.greybeard-data}/output/code-review/$repo"
slug="$(printf '%s' "$branch" | tr '/' '-')"

newest=""
newest_sha=""
for f in "$data"/runs/*.md "$data"/fix-runs/*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in
    *"$slug"*) ;;
    *) grep -q -F -- "$branch" "$f" || continue ;;
  esac
  sha="$(grep -h -o -E '^\*\*(HEAD SHA|Final SHA):\*\* *[0-9a-f]{7,40}' "$f" | tail -1 | grep -o -E '[0-9a-f]{7,40}$' || true)"
  [ -n "$sha" ] || continue
  if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then
    newest="$f"
    newest_sha="$sha"
  fi
done

if [ -z "$newest_sha" ]; then
  echo "no reviewed SHA recorded for $repo $branch under $data"
  exit 2
fi

echo "last reviewed: $newest_sha ($(basename "$newest"))"
echo "head:          $head"
case "$head" in "$newest_sha"*) echo "match"; exit 0 ;; esac
case "$newest_sha" in "$head"*) echo "match"; exit 0 ;; esac

branch_patch_id() {
  local base
  base="$(git merge-base origin/main "$1" 2>/dev/null)" || return 1
  git diff "$base" "$1" | git patch-id --stable | awk '{print $1}'
}
if git cat-file -e "$newest_sha^{commit}" 2>/dev/null; then
  reviewed_pid="$(branch_patch_id "$newest_sha" || true)"
  head_pid="$(branch_patch_id "$head" || true)"
  if [ -n "$reviewed_pid" ] && [ "$reviewed_pid" = "$head_pid" ]; then
    echo "match (same branch diff as the reviewed SHA; rebased or amended message only)"
    exit 0
  fi
fi
echo "HEAD is not the last reviewed SHA; run review --fix before pushing"
exit 1
