#!/usr/bin/env bash
# Behavior tests for pr-worktree.sh. Run: bash workflows/code-review/scripts/test/pr_worktree_test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../pr-worktree.sh"
passed=0
failed=0

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/pr-worktree-test.XXXXXX")" || exit 1
  export GREYBEARD_DATA="$WORK/data"
  CLONE="$GREYBEARD_DATA/sources/app"
  mkdir -p "$CLONE"
  cd "$CLONE" || exit 1
  git init -q -b main
  git config user.email test@example.com
  git config user.name Test
  git config commit.gpgsign false
  echo base > app.rb && git add -A && git commit -q -m initial
  git update-ref refs/remotes/origin/main HEAD
  git checkout -q -b scratch
  echo feature > app.rb && git commit -q -am feature
  git update-ref refs/remotes/origin/feature HEAD
  git update-ref refs/remotes/origin/team/topic HEAD
  git checkout -q main
  git branch -q -D scratch
  cd "$WORK" || exit 1
}

run() { bash "$SCRIPT" "$@" > "$WORK/out" 2>&1; echo "exit $?" >> "$WORK/out"; }
out_line() { sed -n "${1}p" "$WORK/out"; }
fail() {
  echo "    $1"
  sed 's/^/      | /' "$WORK/out"
  exit 1
}
assert_eq() { [ "$1" = "$2" ] || fail "expected [$2], got [$1]"; }

it() {
  local name="$1"
  shift
  if (setup && "$@"); then
    echo "  pass: $name"
    passed=$((passed + 1))
  else
    echo "  FAIL: $name"
    failed=$((failed + 1))
  fi
}

add_creates_a_detached_worktree_at_the_pr_head() {
  run add app feature 12
  assert_eq "$(out_line 1)" "$GREYBEARD_DATA/sources/app-pr12"
  assert_eq "$(tail -1 "$WORK/out")" "exit 0"
  assert_eq "$(git -C "$GREYBEARD_DATA/sources/app-pr12" rev-parse HEAD)" "$(git -C "$CLONE" rev-parse origin/feature)"
  assert_eq "$(git -C "$GREYBEARD_DATA/sources/app-pr12" rev-parse --abbrev-ref HEAD)" "HEAD"
}

add_leaves_the_shared_clone_on_its_branch() {
  run add app feature 12
  assert_eq "$(git -C "$CLONE" rev-parse --abbrev-ref HEAD)" "main"
  assert_eq "$(cat "$CLONE/app.rb")" "base"
}

add_again_moves_the_worktree_to_the_new_head() {
  run add app feature 12
  git -C "$GREYBEARD_DATA/sources/app-pr12" checkout -q --detach origin/main
  run add app feature 12
  assert_eq "$(tail -1 "$WORK/out")" "exit 0"
  assert_eq "$(git -C "$GREYBEARD_DATA/sources/app-pr12" rev-parse HEAD)" "$(git -C "$CLONE" rev-parse origin/feature)"
}

add_without_a_pr_number_names_the_worktree_after_the_branch() {
  run add app team/topic
  assert_eq "$(out_line 1)" "$GREYBEARD_DATA/sources/app-team-topic"
  assert_eq "$(git -C "$GREYBEARD_DATA/sources/app-team-topic" rev-parse HEAD)" "$(git -C "$CLONE" rev-parse origin/team/topic)"
}

add_refuses_an_unfetched_branch_and_says_to_fetch() {
  run add app missing 7
  assert_eq "$(tail -1 "$WORK/out")" "exit 1"
  grep -q "git -C $CLONE fetch origin main missing" "$WORK/out" || fail "expected the fetch command in the error"
  [ ! -e "$GREYBEARD_DATA/sources/app-pr7" ] || fail "worktree should not exist"
}

remove_deletes_the_worktree_and_its_registration() {
  run add app feature 12
  run remove app 12
  assert_eq "$(tail -1 "$WORK/out")" "exit 0"
  [ ! -e "$GREYBEARD_DATA/sources/app-pr12" ] || fail "worktree dir still exists"
  git -C "$CLONE" worktree list | grep -q "app-pr12" && fail "worktree still registered"
  assert_eq "$(git -C "$CLONE" rev-parse --abbrev-ref HEAD)" "main"
}

remove_of_a_missing_worktree_is_a_no_op() {
  run remove app 99
  assert_eq "$(tail -1 "$WORK/out")" "exit 0"
}

echo "pr-worktree.sh"
it "add creates a detached worktree at the PR head" add_creates_a_detached_worktree_at_the_pr_head
it "add leaves the shared clone on its branch" add_leaves_the_shared_clone_on_its_branch
it "add again moves the worktree to the new head" add_again_moves_the_worktree_to_the_new_head
it "add without a PR number names the worktree after the branch" add_without_a_pr_number_names_the_worktree_after_the_branch
it "add refuses an unfetched branch and says to fetch" add_refuses_an_unfetched_branch_and_says_to_fetch
it "remove deletes the worktree and its registration" remove_deletes_the_worktree_and_its_registration
it "remove of a missing worktree is a no-op" remove_of_a_missing_worktree_is_a_no_op
echo "passed: $passed, failed: $failed"
[ "$failed" -eq 0 ]
