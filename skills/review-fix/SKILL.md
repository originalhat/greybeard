---
name: review-fix
description: >-
  Auto-fix loop on top of code review. Use when the user says "review --fix",
  "fix this branch", "auto-fix mode", or "review and fix" — classifies the
  review's findings, auto-applies the safe ones, commits them separately from
  the author's original commits, and re-reviews with a fresh pass — looping
  (bounded) until nothing auto-fixable remains or a 3-round cap is hit. Never
  pushes; only runs on a branch the user can write to. Produces a one-shot
  fix-run audit record. This is the `--fix` mode of the `review` verb, not a
  separate trigger word.
---

# Review — Auto-Fix Mode

Runs the same lenses and context as `review`, then classifies findings,
auto-applies the safe ones, commits them, and re-reviews in a bounded loop.

**Trigger:** `review --fix` / `review --fix <branch-name> in <repo-name>`, or
equivalent phrasing ("fix this branch", "auto-fix mode", "review and fix").

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md`.

That file drives the 3-phase `pipeline/` (triage → fixer → gate, one pass per
round) and writes a one-shot audit record to
`$GREYBEARD_DATA/output/code-review/{repo}/fix-runs/` (default
`~/.greybeard-data/`). It never pushes, and only runs on a branch the user
owns — reviewing someone else's PR stays on plain `review`.
