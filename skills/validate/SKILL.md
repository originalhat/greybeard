---
name: validate
description: >-
  Drive a real browser against a running app to check a change against
  acceptance criteria. Use when the user says "validate <ticket>", "validate
  this branch", "check acceptance criteria", "browser test this", or asks to
  verify a UI change actually works. Takes the same ticket/requirements input
  as `implement` (a JIRA ticket URL/ID, a GitHub issue URL, or freeform
  requirements), optionally `in <repo>`, and reports pass/fail per criterion
  from what it actually saw in the browser. Pass `--exploratory` (or "explore
  beyond the ACs", "poke at it", "exploratory testing", "find edge cases") to
  follow up with a bounded, loop-based round of open-ended testing beyond the
  stated criteria. Read-only — never modifies code, never commits.
---

# Validate

Ticket or requirements in, driven browser session out: pass/fail per
acceptance criterion, plus — with `--exploratory` — a bounded round of
open-ended probing beyond what was specified.

**Trigger:** `validate <Jira ticket URL | ticket ID | GitHub issue URL | freeform requirements>`, optionally `in <repo-name>`, optionally `--exploratory`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/validate/AGENTS.md`.

That file holds the full pipeline: intake → scope check → launch →
acceptance check (`pipeline/01-acceptance-check.md`) → if `--exploratory`,
bounded exploratory loop (`pipeline/02-exploratory.md`) → report.

Target repos live under `$GREYBEARD_DATA/sources/{repo}/` (default
`~/.greybeard-data/`). Needs the `atlassian` MCP for JIRA tickets and `gh`
for GitHub issues; neither for freeform requirements. Needs the `playwright`
MCP to drive the browser.

This is a separate step from `implement` — chain them explicitly:
`implement <ticket>` to build it, then `validate <ticket>` (optionally
`--exploratory`) once the branch exists.
