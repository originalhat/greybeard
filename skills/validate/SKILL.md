---
name: validate
description: >-
  General-purpose QA of a change against running software, as a creative
  human tester would do it: check that it does what it claims, then explore
  at and around it to find what nobody specified. Use when the user says
  "validate <ticket>", "validate this branch", "qa this", "QA this PR",
  "check acceptance criteria", "browser test this", "exploratory test", "bug
  bash", "try to break this", "poke at it", or "find edge cases". Takes a
  Jira ticket URL/ID, a GitHub issue URL, a GitHub PR URL, a branch `in
  <repo>`, or freeform requirements. Drives a browser for UI changes, and
  uses HTTP calls or a local console for APIs, jobs, and model rules. Checks
  each stated criterion, then loops through bounded exploratory sessions
  (inputs, counts and position, entities and CRUD, states and transitions,
  timing, following the data, the ecosystem, roles, navigation, small
  screens), following up on bugs and leads between rounds. It replays every
  finding before reporting it, and reports bugs with repro steps ranked by
  user impact, questions for the author, and coverage. `--check-only` skips
  exploration; `--rounds N` (default 4); `--url <base-url>` for a
  non-production environment. Never touches production, never modifies code,
  never commits.
---

# Validate

A ticket, PR, or branch in; running software used like a curious human
tester would use it; a report of what works, what users will trip on, and
how hard we looked out.

**Trigger:** `validate <Jira ticket URL | ticket ID | GitHub issue URL | GitHub PR URL | freeform requirements>`, or `validate <branch-name> in <repo-name>`. Optional `--check-only`, `--rounds N`, `--url <base-url>`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/validate/AGENTS.md`.

That file holds the full pipeline: intake, pick the interfaces (browser, HTTP,
console), launch, change map, check
(`pipeline/01-acceptance-check.md`), then charter, the explore loop, and
confirm (`pipeline/02-exploratory.md`), and the report per
`${CLAUDE_PLUGIN_ROOT}/workflows/validate/templates/VALIDATION-REPORT.md`.
Every agent gets `${CLAUDE_PLUGIN_ROOT}/workflows/validate/PERSONA.md` and
the lenses its charters name from
`${CLAUDE_PLUGIN_ROOT}/workflows/validate/lenses/`.

Target repos live under `$GREYBEARD_DATA/sources/{repo}/` (default
`~/.greybeard-data/`). Needs the `playwright` MCP for UI changes, the GitHub
MCP for PRs, and the `atlassian` MCP for Jira tickets.

Chain it after `implement`: `implement <ticket>` to build it, then
`validate <ticket>` once the branch exists.
