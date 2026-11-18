---
name: improve
description: >-
  Continuously improve an existing codebase in small, safe steps. Use when the
  user says "improve", "improve --rounds 10", "improve in <repo>", "improve
  discover", "find something to improve", "what should we clean up", "boy
  scout this repo", "improve status", "improve reject I-<n>", or "improve
  I-<n>". A run is N rounds (`--rounds N`, default 1) on one
  `improve/<date>-batch` branch, each round in its own subagent: scout one
  slice of 2-3 related files (picked by churn and past review findings, never
  re-reading unchanged files) through the code-review lenses, record what it
  learned in a per-repo knowledge base (conventions, recurring patterns, a
  backlog of evidence-backed candidates), and build the best backlog candidate
  through `implement` as reviewed commits. Then one `validate` of the combined
  behavior changes, defects found along the way filed in Linear (Defects
  project, `improve-workflow` label), and with `--pr` one draft PR. Patterns
  seen across 3 slices become cross-cutting candidates; work too big for a
  round becomes a proposed ticket (filed only on approval) recommending one
  PR or, past a high bar, a campaign. Behavior-preserving changes are the default; small behavior
  changes with a big structural payoff are built but flagged with before/after
  screenshots. Optional `--focus <path>`, `--worktree`, `--pr`,
  `--no-validate`, `--no-file`, `discover --slices N`. Never stacks PRs,
  never merges.
---

# Improve

N rounds on one branch: scout a slice, record what it taught, build the best thing in the backlog. Then validate once, file the defects, and open one draft PR.

**Trigger:** `improve [in <repo>] [--rounds N] [--focus <path>] [--worktree] [--pr] [--no-validate] [--no-file]`, `improve discover [--slices N]`, `improve I-<n> [I-<m> …]`, `improve status`, `improve reject I-<n> "<why>"`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/improve/AGENTS.md`.

That file makes the batch branch, then runs each round in a subagent through
`pipeline/01-slice.md` to `04-build.md` (`scripts/pick-slice.sh`, Sonnet
scouts applying `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/lenses/` to the
existing code, the knowledge base in `$GREYBEARD_DATA/output/improve/{repo}/`,
`implement` with a review of only that round, `scripts/scope-gate.sh`). The
parent checks each round and steers the next through a shared brief, then
runs `pipeline/05-finish.md`: catch up with main, validate, file defects, PR.

**Commits are authorized.** Saying `improve` or `improve I-<n>` is the user's
explicit request to commit, the same as saying "commit": `implement`'s
commits, its fix commits, `review --fix` commits, and the finish's fix
commits, on the run's own `improve/<date>-batch` branch only. That satisfies a
"never commit unless I say so" rule for this branch. It does not extend to
`main`, the user's branches, or pushing, which still needs `--pr` or a `pr`
reply. Filing the run's defect tickets in Linear is authorized the same way
(`--no-file` turns it off); refactor tickets are only proposed, and filed
when the user answers `file`. `improve discover`, `improve status`,
and `improve reject` never commit or file.
