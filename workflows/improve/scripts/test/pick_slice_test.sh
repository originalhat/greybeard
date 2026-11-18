#!/usr/bin/env bash
# Behavior tests for pick-slice.sh. Run: bash workflows/improve/scripts/test/pick_slice_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PICK="$HERE/../pick-slice.sh"
passed=0
failed=0

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/pick-slice-test.XXXXXX")" || exit 1
  export GREYBEARD_DATA="$WORK/data"
  STATE_DIR="$GREYBEARD_DATA/output/improve/app"
  RUNS="$GREYBEARD_DATA/output/code-review/app/runs"
  mkdir -p "$STATE_DIR" "$RUNS" "$WORK/repo"
  unset IMPROVE_BASE IMPROVE_SINCE IMPROVE_SWEEP_FILES
  cd "$WORK/repo" || exit 1
  git init -q -b main
  git config user.email test@example.com
  git config user.name Test
  git config commit.gpgsign false
  echo "# app" > README.md
  git add -A && git commit -q -m "initial"
  publish
}

publish() { git update-ref refs/remotes/origin/main HEAD; }
touch_files() {
  local f
  for f in "$@"; do mkdir -p "$(dirname "$f")"; echo "$RANDOM $f" >> "$f"; done
  git add -A && git commit -q -m "touch $*"
}
commits() { local n="$1"; shift; local i; for i in $(seq 1 "$n"); do touch_files "$@"; done; }
finding() {
  printf '| 1 | LENS | something | %s | pre-existing | why |\n' "$1" >> "$RUNS/2026-11-01-run-$RANDOM.md"
}
visited() {
  local path="$1" sha="${2:-$(git rev-parse origin/main)}"
  local file="$STATE_DIR/state.json"
  [ -f "$file" ] || echo '{"visits":[]}' > "$file"
  jq --arg p "$path" --arg s "$sha" '.visits += [{"path":$p,"sha":$s,"at":"2026-11-01"}]' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
pick() { "$PICK" app "$@" > "$WORK/out" 2>&1; echo "exit $?" >> "$WORK/out"; }
anchor() { sed -n 's/^anchor //p' "$WORK/out"; }
withs() { sed -n 's/^with //p' "$WORK/out" | paste -sd, -; }

fail() {
  echo "    $1"
  sed 's/^/      | /' "$WORK/out"
  exit 1
}
assert_eq() { [ "$1" = "$2" ] || fail "expected [$2], got [$1]"; }
assert_out_contains() { grep -qF -- "$1" "$WORK/out" || fail "expected output to contain [$1]"; }

it() {
  local name="$1"
  if ( setup && "$2" ); then
    passed=$((passed + 1)); echo "ok   $name"
  else
    failed=$((failed + 1)); echo "FAIL $name"
  fi
}

anchors_on_the_file_that_changes_most() {
  commits 3 app/busy.rb
  commits 1 app/quiet.rb
  publish
  pick
  assert_eq "$(anchor)" "app/busy.rb"
  assert_out_contains "ref $(git rev-parse origin/main)"
  assert_out_contains "3 commits"
}

pre_existing_review_findings_raise_a_files_rank() {
  commits 3 app/busy.rb
  commits 1 app/flagged.rb
  publish
  finding "app/flagged.rb:12"
  finding "app/flagged.rb:40-44"
  pick
  assert_eq "$(anchor)" "app/flagged.rb"
  assert_out_contains "2 pre-existing review findings"
}

findings_recorded_with_a_partial_path_still_count() {
  commits 2 client/src/Thing/index.tsx
  commits 2 client/src/Other/index.tsx
  publish
  finding "Thing/index.tsx"
  pick
  assert_eq "$(anchor)" "client/src/Thing/index.tsx"
}

never_anchors_on_a_test_file() {
  commits 5 spec/models/thing_spec.rb client/src/Thing.test.tsx
  commits 1 app/models/thing.rb
  publish
  pick
  assert_eq "$(anchor)" "app/models/thing.rb"
}

never_anchors_on_generated_or_risky_paths() {
  commits 5 Gemfile.lock db/migrate/20261101_add.rb db/schema.rb config/routes.rb vendor/lib.rb docs/guide.md
  commits 1 app/models/thing.rb
  publish
  pick
  assert_eq "$(anchor)" "app/models/thing.rb"
}

skips_a_file_visited_at_a_ref_it_has_not_changed_since() {
  commits 3 app/busy.rb
  commits 1 app/quiet.rb
  publish
  visited app/busy.rb
  pick
  assert_eq "$(anchor)" "app/quiet.rb"
}

revisits_a_file_that_changed_after_its_visit() {
  commits 3 app/busy.rb
  commits 1 app/quiet.rb
  publish
  visited app/busy.rb
  commits 1 app/busy.rb
  publish
  pick
  assert_eq "$(anchor)" "app/busy.rb"
}

none_when_every_file_was_visited_and_is_unchanged() {
  commits 1 app/only.rb
  publish
  visited app/only.rb
  pick
  assert_eq "$(head -1 "$WORK/out")" "none"
  assert_out_contains "exit 0"
}

adds_the_files_that_change_with_the_anchor() {
  commits 3 app/models/thing.rb spec/models/thing_spec.rb
  commits 2 app/models/thing.rb app/services/thing_sync.rb
  commits 1 app/models/thing.rb app/helpers/rare.rb
  publish
  pick
  assert_eq "$(anchor)" "app/models/thing.rb"
  assert_eq "$(withs)" "spec/models/thing_spec.rb,app/services/thing_sync.rb"
}

slice_size_can_be_changed() {
  commits 3 app/models/thing.rb spec/models/thing_spec.rb
  commits 2 app/models/thing.rb app/services/thing_sync.rb
  publish
  pick --size 2
  assert_eq "$(withs)" "spec/models/thing_spec.rb"
}

ignores_sweeping_commits_when_finding_collaborators() {
  local many=() i
  for i in $(seq 1 25); do many+=("app/sweep/f$i.rb"); done
  commits 3 app/models/thing.rb "${many[@]}"
  commits 1 app/models/thing.rb app/services/real.rb
  commits 4 app/models/thing.rb
  publish
  pick --focus app/models
  assert_eq "$(withs)" "app/services/real.rb"
}

skips_collaborators_deleted_since() {
  commits 2 app/models/thing.rb app/services/gone.rb
  commits 1 app/models/thing.rb app/services/kept.rb
  git rm -q app/services/gone.rb && git commit -q -m "remove gone"
  publish
  pick --focus app/models
  assert_eq "$(withs)" "app/services/kept.rb"
}

focus_limits_anchors_to_a_path() {
  commits 5 app/models/thing.rb
  commits 1 client/src/Widget.tsx
  publish
  pick --focus client/src
  assert_eq "$(anchor)" "client/src/Widget.tsx"
}

reads_the_base_ref_not_the_checkout() {
  commits 1 app/published.rb
  publish
  commits 4 app/local_only.rb
  pick
  assert_eq "$(anchor)" "app/published.rb"
}

ties_break_by_path() {
  commits 1 app/b.rb
  commits 1 app/a.rb
  publish
  pick
  assert_eq "$(anchor)" "app/a.rb"
}

it "anchors on the file that changes most" anchors_on_the_file_that_changes_most
it "pre-existing review findings raise a file's rank" pre_existing_review_findings_raise_a_files_rank
it "findings recorded with a partial path still count" findings_recorded_with_a_partial_path_still_count
it "never anchors on a test file" never_anchors_on_a_test_file
it "never anchors on generated or risky paths" never_anchors_on_generated_or_risky_paths
it "skips a file visited at a ref it has not changed since" skips_a_file_visited_at_a_ref_it_has_not_changed_since
it "revisits a file that changed after its visit" revisits_a_file_that_changed_after_its_visit
it "none when every file was visited and is unchanged" none_when_every_file_was_visited_and_is_unchanged
it "adds the files that change with the anchor" adds_the_files_that_change_with_the_anchor
it "slice size can be changed" slice_size_can_be_changed
it "ignores sweeping commits when finding collaborators" ignores_sweeping_commits_when_finding_collaborators
it "skips collaborators deleted since" skips_collaborators_deleted_since
it "focus limits anchors to a path" focus_limits_anchors_to_a_path
it "reads the base ref, not the checkout" reads_the_base_ref_not_the_checkout
it "ties break by path" ties_break_by_path

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
