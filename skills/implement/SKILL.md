---
name: implement
description: >-
  Turn a ticket or a set of requirements into working, tested, reviewed, and
  validated code on a branch. Use when the user says "implement <ticket>", "implement this
  ticket", "build <feature>", "implement these requirements", or gives a Linear
  issue URL/ID, a JIRA ticket URL/ID, a GitHub issue URL, or pasted freeform
  requirements to build, optionally `in <repo>`. Pass `--worktree` to work in
  a sibling git worktree, with its own local stack via the repo's
  `bin/worktree-setup` when present. Investigates the target codebase, implements
  test-first (red then green, testing behavior not implementation), commits,
  then runs a code review and then `validate` (exploratory QA) on that
  commit, with a one-screenshot render check for UI changes (`--skip-ui` skips
  the browser; `--no-validate` skips QA). One fix pass applies the safe review
  fixes, fixes validate's bugs test-first, and takes the agent's own
  recommendation on judgment calls; a scoped `review --fix` covers only those
  fixes. Asks mid-run only what changes what gets built, and ends with one
  list of decisions to answer by number. A stacked branch (`--base`) skips
  validate; validate the stack once with `validate --stack`. Picks the smallest
  design that meets the acceptance criteria and reports the alternative as not
  built. For a Linear issue, attaches an agent-summary.md to it as the point of
  record. Never pushes or opens a PR unless `--pr` is passed, which opens a
  draft.
---

# Implement

Ticket or requirements in; a test-first, reviewed, validated branch and one list of decisions out.

**Trigger:** `implement <Linear issue | Jira ticket URL | ticket ID | GitHub issue URL | freeform requirements>`, optionally `in <repo-name>`, `--worktree` (with optional `--base <branch>` for stacked work), `--skip-ui`, `--no-validate`, `--pr`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/implement/AGENTS.md`.

`--worktree` leaves the main checkout alone: the branch lives in a sibling
worktree (`<checkout>-<ticket>`), every step runs from there against that
worktree's own stack, and the worktree and stack are left up for the human.

That file holds the full pipeline: intake → investigate → TDD (red, green,
refactor, one behavior at a time) → commit → review, render check, then validate on the same commit
(`${CLAUDE_PLUGIN_ROOT}/workflows/code-review/AGENTS.md`, then
`${CLAUDE_PLUGIN_ROOT}/workflows/validate/AGENTS.md`) → one fix pass with
optimistic decisions → scoped `review --fix` via
`${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/AGENTS.md` and `validate
--check-only` → one closing list of decisions → draft PR only with `--pr` →
`agent-summary.md` attached to the Linear issue.

Needs the `Linear` MCP for Linear issues, the `atlassian` MCP for JIRA tickets,
and `gh` for GitHub issues; none for freeform requirements.
