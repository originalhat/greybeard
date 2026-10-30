#!/usr/bin/env bash
# Behavior tests for review-scope.sh. Run: bash workflows/code-review/scripts/test/review_scope_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCOPE="$HERE/../review-scope.sh"
passed=0
failed=0

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/review-scope-test.XXXXXX")" || exit 1
  export GREYBEARD_DATA="$WORK/data"
  RUNS="$GREYBEARD_DATA/output/code-review/app/runs"
  mkdir -p "$RUNS" "$WORK/repo"
  unset REVIEW_BASE
  cd "$WORK/repo" || exit 1
  git init -q -b main
  git config user.email test@example.com
  git config user.name Test
  git config commit.gpgsign false
  lines 100 > app.rb
  git add -A && git commit -q -m "initial"
  git update-ref refs/remotes/origin/main HEAD
  git checkout -q -b feature
}

lines() { local i; for i in $(seq 1 "$1"); do echo "${2:-line} $i"; done; }
commit_file() { mkdir -p "$(dirname "$1")"; lines "$2" "${3:-$1}" > "$1"; git add -A && git commit -q -m "edit $1"; }
record_review() {
  sleep 1
  printf '# Review Run\n\n**HEAD SHA:** %s\n' "$(git rev-parse HEAD)" > "$RUNS/2026-10-30-feature-$(git rev-parse --short HEAD).md"
}
scope() { "$SCOPE" app feature > "$WORK/out" 2>&1; echo "exit $?" >> "$WORK/out"; head -1 "$WORK/out"; }

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

full_when_the_branch_was_never_reviewed() {
  commit_file feature.rb 50
  assert_eq "$(scope)" "full"
  assert_out_contains "no prior review"
}

reviewed_when_head_is_the_reviewed_sha() {
  commit_file feature.rb 50
  record_review
  assert_eq "$(scope)" "reviewed $(git rev-parse HEAD)"
}

scoped_to_the_new_commits_when_the_delta_is_small() {
  commit_file feature.rb 100
  record_review
  local reviewed; reviewed="$(git rev-parse HEAD)"
  commit_file small.rb 10
  assert_eq "$(scope)" "scoped $reviewed"
  assert_out_contains "1 file"
}

full_when_the_delta_is_a_large_share_of_the_branch() {
  commit_file feature.rb 100
  record_review
  commit_file big.rb 60
  assert_eq "$(scope)" "full"
  assert_out_contains "over 30%"
}

threshold_can_be_raised() {
  commit_file feature.rb 100
  record_review
  local reviewed; reviewed="$(git rev-parse HEAD)"
  commit_file big.rb 60
  assert_eq "$(SCOPE_MAX_PERCENT=50 scope)" "scoped $reviewed"
}

full_when_the_delta_touches_a_migration() {
  commit_file feature.rb 100
  record_review
  commit_file db/migrate/20261030_add_column.rb 5
  assert_eq "$(scope)" "full"
  assert_out_contains "db/migrate/20261030_add_column.rb"
}

full_when_the_delta_touches_config() {
  commit_file feature.rb 100
  record_review
  commit_file config/routes.rb 3
  assert_eq "$(scope)" "full"
  assert_out_contains "config/routes.rb"
}

scoped_to_the_rebased_copy_of_the_reviewed_commit() {
  commit_file feature.rb 100
  record_review
  git checkout -q main
  commit_file other.rb 20
  git update-ref refs/remotes/origin/main HEAD
  git checkout -q feature
  git rebase -q main
  local rebased; rebased="$(git rev-parse HEAD)"
  commit_file small.rb 10
  assert_eq "$(scope)" "scoped $rebased"
}

full_when_the_reviewed_commit_was_rewritten() {
  commit_file feature.rb 100
  record_review
  lines 100 changed > feature.rb
  git commit -q -a --amend -m "rewritten"
  commit_file small.rb 5
  assert_eq "$(scope)" "full"
  assert_out_contains "not in this branch's history"
}

stacked_branch_measures_against_its_parent() {
  commit_file parent.rb 500
  git update-ref refs/remotes/origin/parent HEAD
  commit_file feature.rb 100
  record_review
  local reviewed; reviewed="$(git rev-parse HEAD)"
  commit_file small.rb 20
  assert_eq "$(SCOPE_MAX_PERCENT=10 scope)" "scoped $reviewed"
  assert_eq "$(REVIEW_BASE=origin/parent SCOPE_MAX_PERCENT=10 scope)" "full"
}

it "full when the branch was never reviewed" full_when_the_branch_was_never_reviewed
it "reviewed when HEAD is the reviewed SHA" reviewed_when_head_is_the_reviewed_sha
it "scoped to the new commits when the delta is small" scoped_to_the_new_commits_when_the_delta_is_small
it "full when the delta is a large share of the branch" full_when_the_delta_is_a_large_share_of_the_branch
it "threshold can be raised with SCOPE_MAX_PERCENT" threshold_can_be_raised
it "full when the delta touches a migration" full_when_the_delta_touches_a_migration
it "full when the delta touches config" full_when_the_delta_touches_config
it "scoped to the rebased copy of the reviewed commit" scoped_to_the_rebased_copy_of_the_reviewed_commit
it "full when the reviewed commit was rewritten" full_when_the_reviewed_commit_was_rewritten
it "stacked branch measures against its parent" stacked_branch_measures_against_its_parent

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
