#!/usr/bin/env bash
# Decides how much of a branch the next review has to cover.
#
# Usage: review-scope.sh <repo> <branch> [head-sha]
#   Run from inside the target repo checkout.
#   REVIEW_BASE=origin/<parent> for a stacked branch (default origin/main).
#   SCOPE_MAX_PERCENT caps the delta's share of the branch diff for a scoped review (default 30).
#
# First line of output, then a `reason:` line:
#   reviewed <sha>  HEAD is already reviewed; nothing to do.
#   scoped <sha>    Review <sha>..HEAD, with the rest of the branch as read-only context.
#   full            Review the whole branch.
set -euo pipefail

repo="${1:?repo}"
branch="${2:?branch}"
head="${3:-$(git rev-parse HEAD)}"
base_ref="${REVIEW_BASE:-origin/main}"
max_percent="${SCOPE_MAX_PERCENT:-30}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set +e
last="$("$here/last-reviewed-sha.sh" "$repo" "$branch" "$head")"
status=$?
set -e

case "$status" in
  0) echo "reviewed $(git rev-parse "$head")"; echo "reason: ${last##*$'\n'}"; exit 0 ;;
  2) echo "full"; echo "reason: no prior review recorded for $branch"; exit 0 ;;
esac

reviewed="$(printf '%s\n' "$last" | sed -n 's/^last reviewed: \([0-9a-f]*\).*/\1/p')"

branch_patch_id() {
  local base
  base="$(git merge-base "$base_ref" "$1" 2>/dev/null)" || return 1
  git diff "$base" "$1" | git patch-id --stable | awk '{print $1}'
}

scope_base=""
if git cat-file -e "$reviewed^{commit}" 2>/dev/null; then
  if git merge-base --is-ancestor "$reviewed" "$head"; then
    scope_base="$(git rev-parse "$reviewed")"
  else
    reviewed_pid="$(branch_patch_id "$reviewed" || true)"
    for c in $(git rev-list "$base_ref..$head"); do
      if [ -n "$reviewed_pid" ] && [ "$(branch_patch_id "$c" || true)" = "$reviewed_pid" ]; then
        scope_base="$c"
        break
      fi
    done
  fi
fi

if [ -z "$scope_base" ]; then
  echo "full"
  echo "reason: reviewed SHA $reviewed is not in this branch's history (rewritten, or rebased with changes)"
  exit 0
fi

changed_lines() { git diff --numstat "$1" "$head" | awk '$1 != "-" { n += $1 + $2 } END { print n + 0 }'; }
delta="$(changed_lines "$scope_base")"
total="$(changed_lines "$(git merge-base "$base_ref" "$head")")"
files="$(git diff --name-only "$scope_base" "$head")"
file_count="$(printf '%s\n' "$files" | grep -c . || true)"
[ "$file_count" = 1 ] && noun=file || noun=files
summary="delta ${scope_base:0:8}..${head:0:8} is $file_count $noun, $delta of $total changed lines"

risky="$(printf '%s\n' "$files" | grep -E '(^|/)(db/|config/)|schema\.rb$|structure\.sql$' | head -1 || true)"
if [ -n "$risky" ]; then
  echo "full"
  echo "reason: $summary, and touches $risky"
  exit 0
fi

if [ "$total" -gt 0 ] && [ $((delta * 100)) -gt $((total * max_percent)) ]; then
  echo "full"
  echo "reason: $summary, over ${max_percent}% of the branch"
  exit 0
fi

echo "scoped $scope_base"
echo "reason: $summary"
