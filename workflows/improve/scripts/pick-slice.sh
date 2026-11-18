#!/usr/bin/env bash
# Picks the next slice for improve to scout: one anchor file plus the files that most often change with it.
#
# Usage: pick-slice.sh <repo> [--focus <path-prefix>] [--size N]
#   Run from inside the target repo checkout. Reads the base ref only, never the working tree.
#   IMPROVE_BASE         ref to read (default origin/main)
#   IMPROVE_SINCE        churn window (default "6 months ago")
#   IMPROVE_SWEEP_FILES  commits touching more files than this don't count as co-changes (default 20)
#
# Output:
#   anchor <path>
#   with <path>          (up to size-1 lines)
#   ref <sha>
#   reason: ...
# or `none` and a reason line when every eligible file was visited and is unchanged since.
set -euo pipefail

repo="${1:?repo}"
shift
focus=""
size=3
while [ $# -gt 0 ]; do
  case "$1" in
    --focus) focus="${2:?--focus needs a path}"; shift 2 ;;
    --size) size="${2:?--size needs a number}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

base="${IMPROVE_BASE:-origin/main}"
since="${IMPROVE_SINCE:-6 months ago}"
sweep="${IMPROVE_SWEEP_FILES:-20}"
output="${GREYBEARD_DATA:-$HOME/.greybeard-data}/output"
state="$output/improve/$repo/state.json"
runs="$output/code-review/$repo/runs"
ref="$(git rev-parse "$base^{commit}")"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/pick-slice.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

code_re='\.(rb|rake|erb|haml|slim|py|go|rs|java|kt|swift|php|cs|ex|exs|js|jsx|mjs|cjs|ts|tsx|vue|svelte|css|scss|sass|less)$'
excluded_re='(^|/)(vendor|node_modules|generated|dist|build|coverage|tmp|log|public|config|bin|db/migrate)/|(^|/)db/(schema\.rb|structure\.sql)$|\.min\.(js|css)$|\.d\.ts$'
test_re='(^|/)(spec|test|tests|__tests__|__mocks__|fixtures|factories|e2e|cypress)/|_(spec|test)\.[a-z]+$|\.(test|spec|stories)\.[a-z]+$'

git ls-tree -r --name-only "$ref" | grep -E "$code_re" | grep -vE "$excluded_re" > "$tmp/eligible" || true
grep -vE "$test_re" "$tmp/eligible" | awk -v focus="$focus" 'focus == "" || index($0, focus) == 1' > "$tmp/anchors" || true

git log --since="$since" --format= --name-only "$ref" | awk 'NF' | sort | uniq -c > "$tmp/churn"

: > "$tmp/findings"
if [ -d "$runs" ]; then
  find "$runs" -name '*.md' -exec grep -h '| pre-existing |' {} + 2>/dev/null \
    | awk -F'|' '{ p = $5; gsub(/`/, "", p); sub(/:.*/, "", p); gsub(/^[ \t]+|[ \t]+$/, "", p); if (p != "") print p }' \
    | sort | uniq -c > "$tmp/findings" || true
fi

: > "$tmp/visits"
if [ -f "$state" ]; then
  jq -r '.visits[]? | [.path, .sha] | @tsv' "$state" > "$tmp/visits"
fi

awk -v churn_file="$tmp/churn" -v findings_file="$tmp/findings" '
  FILENAME == churn_file { churn[$2] = $1; next }
  FILENAME == findings_file { n = $1; sub(/^ *[0-9]+ /, ""); findings[$0] = n; next }
  {
    f = $0; hits = 0
    for (p in findings) {
      if (f == p || (length(f) > length(p) && substr(f, length(f) - length(p)) == "/" p)) hits += findings[p]
    }
    c = (f in churn) ? churn[f] : 0
    printf "%d\t%s\t%d\t%d\n", c + 2 * hits, f, c, hits
  }
' "$tmp/churn" "$tmp/findings" "$tmp/anchors" | sort -t $'\t' -k1,1nr -k2,2 > "$tmp/ranked"

unchanged_since_visit() {
  local path="$1" sha
  sha="$(awk -F'\t' -v p="$path" '$1 == p { s = $2 } END { print s }' "$tmp/visits")"
  [ -n "$sha" ] || return 1
  git cat-file -e "$sha^{commit}" 2>/dev/null || return 1
  [ -z "$(git log -1 --format=%H "$sha..$ref" -- "$path")" ]
}

anchor=""
while IFS=$'\t' read -r _score path commits hits; do
  if unchanged_since_visit "$path"; then continue; fi
  anchor="$path"
  break
done < "$tmp/ranked"

if [ -z "$anchor" ]; then
  echo "none"
  echo "reason: every eligible file${focus:+ under $focus} was visited and is unchanged since"
  exit 0
fi

git log --format='@%H' --name-only --full-diff -n 200 "$ref" -- "$anchor" \
  | awk -v anchor="$anchor" -v sweep="$sweep" '
      function flush() { if (n > 0 && n <= sweep) for (i = 1; i <= n; i++) if (files[i] != anchor) together[files[i]]++; n = 0 }
      /^@/ { flush(); next }
      NF { files[++n] = $0 }
      END { flush(); for (f in together) printf "%d\t%s\n", together[f], f }
    ' \
  | sort -t $'\t' -k1,1nr -k2,2 \
  | awk -F'\t' 'NR == FNR { eligible[$0] = 1; next } ($2 in eligible) { print $2 }' "$tmp/eligible" - \
  | head -n $((size - 1)) > "$tmp/with" || true

echo "anchor $anchor"
sed 's/^/with /' "$tmp/with"
echo "ref $ref"
echo "reason: $commits commits since $since, $hits pre-existing review findings"
