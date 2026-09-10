---
name: implement
description: >-
  Turn a ticket or a set of requirements into working, tested, reviewed code on
  a branch. Use when the user says "implement <ticket>", "implement this
  ticket", "build <feature>", "implement these requirements", or gives a JIRA
  ticket URL/ID, a GitHub issue URL, or pasted freeform requirements to build,
  optionally `in <repo>`. Investigates the target codebase, implements
  test-first (red then green, testing behavior not implementation), commits
  once complete, runs `review --fix` against the branch, applies any remaining
  in-scope corrections in a separate commit, and — when the change is reachable
  through a UI — spawns a subagent to drive it in a real browser against the
  acceptance criteria. Never pushes, never opens a PR.
---

# Implement

Ticket or requirements in; a test-first, reviewed, and (where applicable)
browser-checked branch out.

**Trigger:** `implement <Jira ticket URL | ticket ID | GitHub issue URL | freeform requirements>`, optionally `in <repo-name>`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/implement/CLAUDE.md`.

That file holds the full pipeline: intake → investigate → TDD (red, green,
refactor, one behavior at a time) → commit → `review --fix` via
`${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md` → correct what's left →
browser-validate when the change has a UI.

Target repos live under `$GREYBEARD_DATA/sources/{repo}/` (default
`~/.greybeard-data/`). Needs the `atlassian` MCP for JIRA tickets and `gh` for
GitHub issues; neither for freeform requirements.
