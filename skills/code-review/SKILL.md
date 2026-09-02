---
name: code-review
description: >-
  Review code changes against technical lenses and team-specific context. Use
  when the user says "review", "review this PR", "code review", "run the
  lenses", or gives a GitHub PR URL / branch + repo to review. Evaluates the
  diff against security, performance, React, TypeScript, data, and architecture
  lenses, fact-checks findings in the repo, and reports an impact-first
  pass/fail tally with numbered failures, one-line nits, and a pre-existing
  section. Also covers cross-repo breaking-change analysis at integration
  points. Pass `--fix` (or "fix this branch", "auto-fix mode", "review and
  fix") to additionally classify findings, auto-apply the safe ones, commit
  them, and loop re-reviews until clean — routes to the review-fix workflow.
  Pass `--interactive` (or "interactive review", "walk through findings",
  "draft comments one by one") to print the report then walk failures 1-by-1,
  drafting a PR comment in the user's voice and posting to GitHub on approval.
---

# Code Review

Multi-stage review of a GitHub PR (or branch) against generalized technical
lenses and repo-specific context.

**Trigger:** `review <github PR URL>` or `review <branch-name> in <repo-name>`.

**Modes:**
- `review --fix` — auto-fix loop. Run `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md` instead of the plain pipeline below.
- `review --interactive` — print the report, then walk failures 1-by-1 drafting PR comments in the user's voice, posting to GitHub only on approval. Same pipeline as plain `review`; the interactive loop runs after the report.

**Run (plain review):** execute `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/CLAUDE.md`.

That file holds the full pipeline: resolve the input, diff against `origin/main`,
evaluate against `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/lenses/` and
`context/`, fact-check (determining pre-existing findings centrally), cross-repo
analysis, and report per
`${CLAUDE_PLUGIN_ROOT}/workflows/code-review/templates/REPORT-FORMAT.md`.

Target repos live under `$GREYBEARD_DATA/sources/{repo}/` (default
`~/.greybeard-data/`). See the root `CLAUDE.md` for the data-directory
convention.
