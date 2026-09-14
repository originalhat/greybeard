#!/usr/bin/env bash
# Generate machine-local copies of every agents/*.md for each tool's own
# agent format:
#   ~/.claude/agents/<name>.md    verbatim (Claude Code frontmatter is canonical)
#   ~/.pi/agent/agents/<name>.md  frontmatter translated to pi-subagents' schema
# Re-run after any change under agents/.
#
# Pi translation: drops `color:` (no Pi equivalent) and `model:` (let the
# agent inherit Pi's configured default model instead of a hardcoded
# Anthropic name), rewrites `memory: <scope>` into pi-subagents' nested
# `memory: { scope, path }` block, and adds inheritProjectContext/inheritSkills
# so the child sees project docs and skills the way a Claude Code subagent
# does by default. The prompt body is copied unchanged.
set -euo pipefail

AGENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_TARGET="$HOME/.claude/agents"
PI_TARGET="$HOME/.pi/agent/agents"

mkdir -p "$CLAUDE_TARGET" "$PI_TARGET"

for agent_file in "$AGENTS_DIR"/*.md; do
  [ -f "$agent_file" ] || continue
  name="$(basename "$agent_file" .md)"

  cp "$agent_file" "$CLAUDE_TARGET/$name.md"

  awk -v name="$name" '
    /^---$/ {
      infm++
      print
      if (infm == 2) {
        print "inheritProjectContext: true"
        print "inheritSkills: true"
      }
      next
    }
    infm == 1 && /^color:/ { next }
    infm == 1 && /^model:/ { next }
    infm == 1 && /^memory:/ {
      scope = $0
      sub(/^memory:[ \t]*/, "", scope)
      gsub(/^[ \t"]+|[ \t"]+$/, "", scope)
      print "memory:"
      print "  scope: " scope
      print "  path: " name
      next
    }
    { print }
  ' "$agent_file" > "$PI_TARGET/$name.md"

  echo "synced $name -> $CLAUDE_TARGET/$name.md, $PI_TARGET/$name.md"
done
