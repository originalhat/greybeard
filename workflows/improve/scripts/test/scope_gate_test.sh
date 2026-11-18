#!/usr/bin/env bash
# Behavior tests for scope-gate.sh. Run: bash workflows/improve/scripts/test/scope_gate_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$HERE/../scope-gate.sh"
passed=0
failed=0

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/scope-gate-test.XXXXXX")" || exit 1
  mkdir -p "$WORK/repo"
  unset IMPROVE_BASE
  cd "$WORK/repo" || exit 1
  git init -q -b main
  git config user.email test@example.com
  git config user.name Test
  git config commit.gpgsign false
  lines 50 > app.rb
  git add -A && git commit -q -m "initial"
  git update-ref refs/remotes/origin/main HEAD
  git checkout -q -b improve/I-1-tidy
}

lines() { local i; for i in $(seq 1 "$1"); do echo "${2:-line} $i"; done; }
change() { mkdir -p "$(dirname "$1")"; lines "${2:-5}" "$1" > "$1"; git add -A && git commit -q -m "change $1"; }
gate() { "$GATE" "$@" > "$WORK/out" 2>&1; echo "exit $?" >> "$WORK/out"; head -1 "$WORK/out"; }

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

passes_a_small_change_to_ordinary_code() {
  change app/models/thing.rb 20
  change spec/models/thing_spec.rb 30
  assert_eq "$(gate)" "pass"
  assert_out_contains "exit 0"
  assert_out_contains "2 files, 50 lines"
}

fails_when_more_files_change_than_the_cap() {
  local i
  for i in $(seq 1 9); do change "app/f$i.rb" 2; done
  assert_eq "$(gate)" "fail"
  assert_out_contains "exit 1"
  assert_out_contains "9 files changed (cap 8)"
}

fails_when_more_lines_change_than_the_cap() {
  change app/big.rb 251
  assert_eq "$(gate)" "fail"
  assert_out_contains "251 lines changed (cap 250)"
}

counts_deleted_lines_too() {
  change app/big.rb 200
  git update-ref refs/remotes/origin/main HEAD
  lines 100 rewritten > app/big.rb
  git add -A && git commit -q -m "rewrite"
  assert_eq "$(gate)" "fail"
  assert_out_contains "lines changed (cap 250)"
}

caps_can_be_raised() {
  local i
  for i in $(seq 1 9); do change "app/f$i.rb" 40; done
  assert_eq "$(gate --max-files 10 --max-lines 400)" "pass"
}

fails_on_a_migration_or_schema() {
  change db/migrate/20261116_add_flag.rb
  change db/schema.rb
  assert_eq "$(gate)" "fail"
  assert_out_contains "db/migrate/20261116_add_flag.rb"
  assert_out_contains "db/schema.rb"
}

fails_on_a_dependency_manifest() {
  change client/package.json
  change Gemfile.lock
  assert_eq "$(gate)" "fail"
  assert_out_contains "client/package.json"
  assert_out_contains "Gemfile.lock"
}

fails_on_routes_and_ci_config() {
  change config/routes.rb
  change .github/workflows/ci.yml
  assert_eq "$(gate)" "fail"
  assert_out_contains "config/routes.rb"
  assert_out_contains ".github/workflows/ci.yml"
}

fails_on_auth_paths() {
  change app/controllers/sessions_controller.rb
  change client/src/Auth/LoginForm.tsx
  change app/policies/patient_policy.rb
  assert_eq "$(gate)" "fail"
  assert_out_contains "app/controllers/sessions_controller.rb"
  assert_out_contains "client/src/Auth/LoginForm.tsx"
  assert_out_contains "app/policies/patient_policy.rb"
}

passes_paths_that_only_look_like_auth() {
  change app/models/author.rb
  change app/models/enrollment.rb
  change client/src/Authored/Byline.tsx
  assert_eq "$(gate)" "pass"
}

measures_against_the_merge_base() {
  change app/models/thing.rb 10
  git checkout -q main
  local i
  for i in $(seq 1 12); do change "app/main_only_$i.rb" 40; done
  git update-ref refs/remotes/origin/main HEAD
  git checkout -q improve/I-1-tidy
  assert_eq "$(gate)" "pass"
  assert_out_contains "1 files, 10 lines"
}

fails_when_the_branch_changes_nothing() {
  assert_eq "$(gate)" "fail"
  assert_out_contains "no changes"
}

lists_every_reason() {
  change app/big.rb 300
  change db/schema.rb
  assert_eq "$(gate)" "fail"
  assert_out_contains "lines changed"
  assert_out_contains "db/schema.rb"
}

it "passes a small change to ordinary code" passes_a_small_change_to_ordinary_code
it "fails when more files change than the cap" fails_when_more_files_change_than_the_cap
it "fails when more lines change than the cap" fails_when_more_lines_change_than_the_cap
it "counts deleted lines too" counts_deleted_lines_too
it "caps can be raised" caps_can_be_raised
it "fails on a migration or schema" fails_on_a_migration_or_schema
it "fails on a dependency manifest" fails_on_a_dependency_manifest
it "fails on routes and CI config" fails_on_routes_and_ci_config
it "fails on auth paths" fails_on_auth_paths
it "passes paths that only look like auth" passes_paths_that_only_look_like_auth
it "measures against the merge base" measures_against_the_merge_base
it "fails when the branch changes nothing" fails_when_the_branch_changes_nothing
it "lists every reason" lists_every_reason

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
