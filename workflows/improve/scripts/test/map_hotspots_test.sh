#!/usr/bin/env bash
# Behavior tests for map-hotspots.sh. Run: bash workflows/improve/scripts/test/map_hotspots_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP="$HERE/../map-hotspots.sh"
passed=0
failed=0

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/map-hotspots-test.XXXXXX")" || exit 1
  mkdir -p "$WORK/repo"
  unset IMPROVE_BASE
  cd "$WORK/repo" || exit 1
  git init -q -b main
  git config user.email test@example.com
  git config user.name Test
  git config commit.gpgsign false
  for f in app/controllers/queue_controller.rb \
           app/controllers/patient_api/care_requests_controller.rb \
           app/controllers/care_requests_controller.rb \
           app/sidekiq/fabric/webhook/event_job.rb \
           app/jobs/send_report_job.rb; do
    mkdir -p "$(dirname "$f")"; echo "# $f" > "$f"
  done
  git add -A && git commit -q -m "initial"
  git update-ref refs/remotes/origin/main HEAD
}

row() { printf '%s\t%s\t%s\t%s\n' "$@"; }
map() { "$MAP" > "$WORK/out" 2> "$WORK/err"; echo "exit $?" >> "$WORK/err"; }
paths() { cut -f1 "$WORK/out" | paste -sd, -; }
weight_of() { awk -F'\t' -v p="$1" '$1 == p { print $2 }' "$WORK/out"; }

fail() {
  echo "    $1"
  sed 's/^/      out | /' "$WORK/out"
  sed 's/^/      err | /' "$WORK/err"
  exit 1
}
assert_eq() { [ "$1" = "$2" ] || fail "expected [$2], got [$1]"; }
assert_contains() { grep -qF -- "$2" "$1" || fail "expected $(basename "$1") to contain [$2]"; }

it() {
  local name="$1"
  if ( setup && "$2" ); then
    passed=$((passed + 1)); echo "ok   $name"
  else
    failed=$((failed + 1)); echo "FAIL $name"
  fi
}

maps_a_controller_action_to_its_controller_file() {
  row web queuecontroller_sidebar_count 1000 0.5 | map
  assert_eq "$(paths)" "app/controllers/queue_controller.rb"
}

maps_a_namespaced_controller() {
  row web patientapi::carerequestscontroller_index 1000 0.5 | map
  assert_eq "$(paths)" "app/controllers/patient_api/care_requests_controller.rb"
}

does_not_confuse_a_namespaced_controller_with_a_top_level_one() {
  row web carerequestscontroller_show 1000 0.5 | map
  assert_eq "$(paths)" "app/controllers/care_requests_controller.rb"
}

maps_jobs_under_sidekiq_and_jobs() {
  { row job fabric::webhook::eventjob 100 2; row job sendreportjob 100 1; } | map
  assert_eq "$(paths)" "app/sidekiq/fabric/webhook/event_job.rb,app/jobs/send_report_job.rb"
}

ranks_by_total_time_with_the_top_weighted_highest() {
  { row web queuecontroller_queue 100 0.1; row job fabric::webhook::eventjob 50 2; } | map
  assert_eq "$(paths)" "app/sidekiq/fabric/webhook/event_job.rb,app/controllers/queue_controller.rb"
  assert_eq "$(weight_of app/sidekiq/fabric/webhook/event_job.rb)" "20"
  assert_eq "$(weight_of app/controllers/queue_controller.rb)" "19"
}

one_line_per_file_keeping_its_best_rank() {
  { row web queuecontroller_sidebar_count 1000 1; row job sendreportjob 100 1; row web queuecontroller_queue 10 1; } | map
  assert_eq "$(paths)" "app/controllers/queue_controller.rb,app/jobs/send_report_job.rb"
  assert_eq "$(weight_of app/controllers/queue_controller.rb)" "20"
  assert_contains "$WORK/out" "queuecontroller_sidebar_count"
  assert_contains "$WORK/out" "queuecontroller_queue"
}

evidence_carries_p95_and_hits() {
  row web queuecontroller_sidebar_count 102345 0.4213 | map
  assert_contains "$WORK/out" "queuecontroller_sidebar_count: p95 0.42s, 102345 hits"
}

reports_resources_it_cannot_map() {
  { row web rails::healthcontroller_show 9000 1; row web queuecontroller_queue 1 1; } | map
  assert_eq "$(paths)" "app/controllers/queue_controller.rb"
  assert_contains "$WORK/err" "unmapped: rails::healthcontroller_show"
  assert_contains "$WORK/err" "exit 0"
}

keeps_only_the_top_twenty_files() {
  local i
  for i in $(seq 1 25); do mkdir -p app/jobs; echo "#" > "app/jobs/job${i}_job.rb"; done
  git add -A && git commit -q -m "jobs" && git update-ref refs/remotes/origin/main HEAD
  for i in $(seq 1 25); do row job "job${i}job" "$i" 1; done | map
  assert_eq "$(wc -l < "$WORK/out" | tr -d ' ')" "20"
  assert_eq "$(weight_of app/jobs/job25_job.rb)" "20"
  assert_eq "$(weight_of app/jobs/job6_job.rb)" "1"
}

reads_the_base_ref_not_the_checkout() {
  mkdir -p app/controllers && echo "#" > app/controllers/local_only_controller.rb
  row web localonlycontroller_index 1000 1 | map
  assert_eq "$(paths)" ""
  assert_contains "$WORK/err" "unmapped: localonlycontroller_index"
}

it "maps a controller action to its controller file" maps_a_controller_action_to_its_controller_file
it "maps a namespaced controller" maps_a_namespaced_controller
it "does not confuse a namespaced controller with a top-level one" does_not_confuse_a_namespaced_controller_with_a_top_level_one
it "maps jobs under app/sidekiq and app/jobs" maps_jobs_under_sidekiq_and_jobs
it "ranks by total time, the top weighted highest" ranks_by_total_time_with_the_top_weighted_highest
it "one line per file, keeping its best rank" one_line_per_file_keeping_its_best_rank
it "evidence carries p95 and hits" evidence_carries_p95_and_hits
it "reports resources it cannot map" reports_resources_it_cannot_map
it "keeps only the top twenty files" keeps_only_the_top_twenty_files
it "reads the base ref, not the checkout" reads_the_base_ref_not_the_checkout

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
