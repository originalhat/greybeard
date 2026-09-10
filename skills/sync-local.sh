#!/usr/bin/env bash
# Generate machine-local copies of every skills/*/SKILL.md for tools that
# can't resolve plugin variables or follow symlinks:
#   ~/.bb/skills/<name>/SKILL.md      bb rejects symlinks anywhere under it
#   ~/.claude/skills/<name>/SKILL.md  Claude Code without the plugin installed
# ${CLAUDE_PLUGIN_ROOT} becomes this checkout; $GREYBEARD_DATA becomes its
# resolved value. Copies previously written here and no longer sourced are
# removed. Re-run after any change under skills/. If the plugin is installed
# via /plugin, skip the ~/.claude/skills target: pass --bb-only.
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SKILLS_DIR")"
DATA_DIR="${GREYBEARD_DATA:-$HOME/.greybeard-data}"
MANIFEST=".sync-local-manifest"

targets=("$HOME/.bb/skills")
[ "${1:-}" = "--bb-only" ] || targets+=("$HOME/.claude/skills")

for target in "${targets[@]}"; do
  mkdir -p "$target"

  if [ -f "$target/$MANIFEST" ]; then
    while read -r stale; do
      [ -n "$stale" ] && [ ! -d "$SKILLS_DIR/$stale" ] && rm -rf "$target/$stale"
    done < "$target/$MANIFEST"
  fi
  : > "$target/$MANIFEST"

  for skill_dir in "$SKILLS_DIR"/*/; do
    name="$(basename "$skill_dir")"
    [ -f "$skill_dir/SKILL.md" ] || continue

    [ -L "$target/$name" ] && rm "$target/$name"
    rm -rf "$target/$name"
    mkdir -p "$target/$name"
    sed -e "s#\${CLAUDE_PLUGIN_ROOT}#$REPO_ROOT#g" \
        -e "s#\${GREYBEARD_DATA:-\$HOME/.greybeard-data}#$DATA_DIR#g" \
        -e "s#\$GREYBEARD_DATA/#$DATA_DIR/#g" \
        "$skill_dir/SKILL.md" > "$target/$name/SKILL.md"
    echo "$name" >> "$target/$MANIFEST"
    echo "synced $name -> $target/$name"
  done
done
