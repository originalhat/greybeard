#!/usr/bin/env bash
# Turns production APM rows into hotspots.tsv lines: the files behind the endpoints and jobs that take the most total time.
#
# Usage: map-hotspots.sh < rows.tsv > hotspots.tsv
#   Run from inside the target repo checkout. Reads the base ref only, never the working tree.
#   IMPROVE_BASE  ref to read (default origin/main)
#
# Input, one row per APM resource: <web|job> <TAB> <resource_name> <TAB> <hits> <TAB> <p95 seconds>
#   web resources look like `patientapi::carerequestscontroller_index` (Datadog's normalized resource_name tag),
#   job resources like `fabric::webhook::eventjob`.
# Output, best first: <path> <TAB> <weight> <TAB> <evidence>
#   Files are ranked by their busiest resource's total time (hits x p95). The top file weighs 20, the 20th weighs 1.
#   Resources that match no file are listed on stderr as `unmapped: <resource>`.
set -euo pipefail

ref="$(git rev-parse "${IMPROVE_BASE:-origin/main}^{commit}")"

files="$(mktemp "${TMPDIR:-/tmp}/map-hotspots.XXXXXX")"
trap 'rm -f "$files"' EXIT

git ls-tree -r --name-only "$ref" -- app/controllers app/sidekiq app/jobs app/workers \
  | awk '/\.rb$/ {
      kind = ($0 ~ /^app\/controllers\//) ? "web" : "job"
      key = $0
      sub(/^app\/(controllers|sidekiq|jobs|workers)\//, "", key)
      sub(/\.rb$/, "", key)
      gsub(/_/, "", key)
      print kind "\t" tolower(key) "\t" $0
    }' > "$files"

awk -F'\t' -v files="$files" '
  BEGIN {
    while ((getline line < files) > 0) { split(line, f, "\t"); path[f[1] SUBSEP f[2]] = f[3] }
  }
  NF >= 4 {
    resource = tolower($2)
    key = resource
    if ($1 == "web") {
      if (match(key, /^.*controller/)) key = substr(key, RSTART, RLENGTH)
    }
    gsub(/::/, "/", key)
    p = path[$1 SUBSEP key]
    if (p == "") { print "unmapped: " $2 > "/dev/stderr"; next }
    printf "%.6f\t%s\t%s: p95 %.2fs, %d hits\n", $3 * $4, p, $2, $4, $3
  }
' | sort -t $'\t' -k1,1gr -k2,2 | awk -F'\t' '
  !($2 in rank) { if (n == 20) next; rank[$2] = ++n; order[n] = $2; evidence[$2] = $3; next }
  { evidence[$2] = evidence[$2] "; " $3 }
  END { for (i = 1; i <= n; i++) printf "%s\t%d\t%s\n", order[i], 21 - i, evidence[order[i]] }
'
