---
name: campaign
description: >-
  Execute large-scale, systematic refactoring campaigns across many files over
  multiple sessions. Use when the user says "campaign plan <goal> in <repo>",
  "campaign continue <campaign> in <repo>", or "campaign status <campaign> in
  <repo>". Covers migrations, architectural transitions, and coverage sweeps.
  The human defines the goal; the pipeline writes the recipe, inventories
  in-scope items, batches them, executes one commit per item, verifies against
  done criteria, and runs a first-pass code review before handing back for merge.
---

# Campaign

Systematic refactoring execution: plan → inventory → batch → execute → verify → review.

**Triggers:**
- `campaign plan <goal> in <repo-name>` — start a new campaign.
- `campaign continue <campaign-name> in <repo-name>` — execute the next batch.
- `campaign status <campaign-name> in <repo-name>` — read-only progress check.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/campaign/CLAUDE.md`.

That file drives the 6-phase `pipeline/` and tracks state in
`$GREYBEARD_DATA/output/campaigns/{repo}/{campaign}/` (default
`~/.greybeard-data/`). Batch review reuses the code-review lenses at
`${CLAUDE_PLUGIN_ROOT}/workflows/code-review/lenses/`.
