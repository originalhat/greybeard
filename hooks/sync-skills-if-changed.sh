#!/usr/bin/env bash
# Stop hook: regenerate the ~/.bb/skills and ~/.claude/skills copies when any
# skills/*/SKILL.md is newer than the last sync, and the ~/.claude/agents copies
# when any agents/*.md is newer than its copy. Hooks run outside the Bash
# sandbox, which is what lets this write to those directories.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$HOME/.bb/skills/.sync-local-manifest"
if [ ! -f "$MANIFEST" ] || [ -n "$(find "$REPO/skills" -name SKILL.md -newer "$MANIFEST" -print -quit)" ]; then
  GREYBEARD_DATA="${GREYBEARD_DATA:-/Users/devin/workspace/greybeard-data}" "$REPO/skills/sync-local.sh" >/dev/null
fi
for agent in "$REPO"/agents/*.md; do
  copy="$HOME/.claude/agents/$(basename "$agent")"
  if [ ! -f "$copy" ] || [ "$agent" -nt "$copy" ]; then
    "$REPO/agents/sync-local.sh" >/dev/null
    break
  fi
done
