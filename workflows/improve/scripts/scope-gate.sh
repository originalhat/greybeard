#!/usr/bin/env bash
# Checks that an improve branch stays inside improve's limits before it can become a PR.
#
# Usage: scope-gate.sh [--max-files N] [--max-lines N]
#   Run from inside the checkout with the improve branch at HEAD.
#   IMPROVE_BASE  ref the branch started from (default origin/main); measured from the merge base.
#
# First line `pass` (exit 0) or `fail` (exit 1), then one `reason:` line per check that failed,
# or a single summary reason on pass.
set -euo pipefail

max_files=8
max_lines=250
while [ $# -gt 0 ]; do
  case "$1" in
    --max-files) max_files="${2:?--max-files needs a number}"; shift 2 ;;
    --max-lines) max_lines="${2:?--max-lines needs a number}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

base="$(git merge-base "${IMPROVE_BASE:-origin/main}" HEAD)"

denied_re='(^|/)db/(migrate/|schema\.rb$|structure\.sql$)|(^|/)migrations/'
denied_re+='|(^|/)(Gemfile|Gemfile\.lock|package\.json|yarn\.lock|package-lock\.json|pnpm-lock\.yaml|requirements[^/]*\.txt|pyproject\.toml|poetry\.lock|go\.mod|go\.sum|Cargo\.toml|Cargo\.lock)$'
denied_re+='|(^|/)\.github/|(^|/)\.circleci/|(^|/)\.gitlab-ci\.yml$|(^|/)Dockerfile[^/]*$|(^|/)docker-compose[^/]*\.ya?ml$|(^|/)config/routes(\.rb|/)'
denied_re+='|(^|[/_.-])(auth|authn|authz|authentication|authorization|sessions?|permissions?|polic(y|ies)|abilit(y|ies)|login|passwords?)([/_.-]|$)'
denied_re+='|(^|/)(Auth|Authn|Authz|Authentication|Authorization|Sessions?|Permissions?|Polic(y|ies)|Abilit(y|ies)|Login|Passwords?)([A-Z/_.-]|$)'

numstat="$(git diff --numstat "$base" HEAD)"
if [ -z "$numstat" ]; then
  echo "fail"
  echo "reason: no changes between $(git rev-parse --short "$base") and HEAD"
  exit 1
fi

files="$(printf '%s\n' "$numstat" | wc -l | tr -d ' ')"
changed="$(printf '%s\n' "$numstat" | awk '{ if ($1 != "-") n += $1 + $2 } END { print n + 0 }')"
denied="$(printf '%s\n' "$numstat" | cut -f3- | grep -E "$denied_re" || true)"

reasons=()
[ "$files" -le "$max_files" ] || reasons+=("$files files changed (cap $max_files)")
[ "$changed" -le "$max_lines" ] || reasons+=("$changed lines changed (cap $max_lines)")
if [ -n "$denied" ]; then
  while IFS= read -r path; do reasons+=("touches $path, which is outside improve's scope (migrations, dependencies, CI, routes, auth)"); done <<< "$denied"
fi

if [ "${#reasons[@]}" -eq 0 ]; then
  echo "pass"
  echo "reason: $files files, $changed lines since $(git rev-parse --short "$base")"
  exit 0
fi

echo "fail"
for r in "${reasons[@]}"; do echo "reason: $r"; done
exit 1
