#!/usr/bin/env bash
# PreToolUse hook for Bash. Warns, never blocks, when a `git push` sends commits
# that no code-review run record has reviewed. Only fires for repos that have a
# $GREYBEARD_DATA/output/code-review/{repo}/ directory, and never for main.
# The check is workflows/code-review/scripts/last-reviewed-sha.sh.

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

PUSH_RE='(^|[;&|(]|\$\()[[:space:]]*git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?push([[:space:]]|$)'
printf '%s\n' "$COMMAND" | grep -qE "$PUSH_RE" || exit 0
printf '%s\n' "$COMMAND" | grep -qE 'push.*(--delete|--tags|[[:space:]]:[^[:space:]])' && exit 0

dir=$(printf '%s\n' "$COMMAND" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+push.*/\1/p' | head -1)
[ -z "$dir" ] && dir=$(printf '%s\n' "$COMMAND" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^[:space:];&|]+).*/\1/p' | head -1)
[ -z "$dir" ] && dir=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
dir=${dir//\"/}
dir=${dir//\'/}
dir=${dir/#\~/$HOME}
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || exit 0

repo=$(basename -s .git "$(git -C "$dir" remote get-url origin 2>/dev/null)")
[ -n "$repo" ] || exit 0
[ -d "${GREYBEARD_DATA:-$HOME/.greybeard-data}/output/code-review/$repo" ] || exit 0
branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
case "$branch" in main|master|HEAD|"") exit 0 ;; esac

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/workflows/code-review/scripts/last-reviewed-sha.sh"
check=$(cd "$dir" && bash "$script" "$repo" "$branch" 2>&1)
rc=$?
[ "$rc" -eq 0 ] && exit 0

range="origin/main..HEAD"
git -C "$dir" rev-parse --verify -q '@{u}' >/dev/null && range='@{u}..HEAD'
commits=$(git -C "$dir" log --format='  %h %s' "$range" 2>/dev/null | head -15)
stat=$(git -C "$dir" diff --shortstat "${range%..HEAD}...HEAD" 2>/dev/null | sed -E 's/^[[:space:]]+//')
reviewed=$(printf '%s\n' "$check" | grep '^last reviewed:' || echo "last reviewed: none recorded")

if [ "$rc" -eq 2 ]; then
  reason="No code-review run record exists for $repo $branch."
else
  reason="HEAD is not the SHA the last code-review run record reviewed."
fi

msg="⚠️⚠️ UNREVIEWED PUSH: $repo $branch ⚠️⚠️
$reason
Being pushed ($range, ${stat:-no diff stat}):
$commits
$reviewed
Run \`review --fix\` on this branch before pushing, or push knowingly."

jq -n --arg msg "$msg" '{
  systemMessage: $msg,
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("WARNING, not a block: this push sends commits no code-review run has reviewed. Tell the user in your next reply, in one line at the top, that the push was unreviewed and which commits it carried, before anything else.\n\n" + $msg)
  }
}'
exit 0
