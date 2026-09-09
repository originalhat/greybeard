# Review-Fix Workflow

A loop-based auto-fix pipeline built on top of `code-review`. Where `review` stops at a report, `review-fix` classifies findings, applies the safe ones, commits them separately, and re-reviews with a fresh pass — bounded, and never on someone else's work.

## Directory Structure

```
review-fix/
├── CLAUDE.md              # You are here
├── pipeline/               # 3-phase loop body
│   ├── 01-triage.md        # Classify findings by remedy scope
│   ├── 02-fixer.md         # Apply auto-fix findings, commit
│   └── 03-gate.md          # Re-review, loop control, ratchet exit ramp
└── templates/
    └── FIX-RUN-RECORD.md   # Audit record format for one run
```

Reuses, unmodified: `../code-review/lenses/`, `../code-review/context/`, `../code-review/templates/REPORT-FORMAT.md`, and the `review` pipeline itself (`../code-review/CLAUDE.md`, and the global `review` skill). `review-fix` never edits lens or context files, and never changes what plain `review` outputs when run on its own.

## Inputs

Triggered by **`review --fix`** (current branch) or **`review --fix <branch> in <repo>`**.

- The current git checkout, under `$GREYBEARD_DATA/sources/{repo}/`. Unlike plain `review`, this is never a PR URL for someone else's fork — `review-fix` commits to the branch it runs against, so it only ever runs on a branch you can write to.
- Everything plain `review` needs: fetched `origin/main`, a three-dot diff, optional PR context.

## Outputs

- Local commits on the branch — one per fix round, kept separate from the author's original commits.
- A final report in `REPORT-FORMAT.md`'s shape, covering whatever `ask-user` findings are still open after the loop stops, prefixed with a short "Auto-fixed" table of what was resolved automatically.
- A run record at `$GREYBEARD_DATA/output/code-review/{repo}/fix-runs/{branch}-{timestamp}.md` per `templates/FIX-RUN-RECORD.md` — rounds run, per-round counts, commits created, final status. One-shot audit trail, not resumable state; there is no catch-up mode for this workflow.
- Never a push. The branch stays local until the human pushes it.

## Execution

### Model Tiers

- **Initial review and every re-review:** unchanged from `review` — Sonnet for lens/context evaluation, Opus for fact-check.
- **Triage (Phase 1):** Opus — the remedy-scope classification is a judgment call, not pattern matching.
- **Fixer (Phase 2):** Sonnet — applies a pre-classified, narrowly-scoped set of fixes. One agent, one pass over all of that round's `auto-fix` findings together, not one agent per finding — fixes in the same file interact, and fixing them independently is how a fix loop starts contradicting itself.
- **Gate (Phase 3):** Opus — decides whether to loop, applies the ratchet exit ramp, assembles the final report.

### Steps

These steps are **strictly sequential** within a round; rounds run one after another, never in parallel.

1. **Initial review**: Run the standard `review` pipeline (`../code-review/CLAUDE.md`, unmodified) against the current branch. This is exactly what plain `review` produces — same lenses, same context, same fact-check.
2. **Triage** (`pipeline/01-triage.md`): Classify every finding from step 1 as `auto-fix`, `ask-user`, or `no-op`.
3. **Fixer** (`pipeline/02-fixer.md`): If there are any `auto-fix` findings, apply them and commit. If there are none, skip straight to step 6.
4. **Gate — re-review** (`pipeline/03-gate.md`): Re-run the standard `review` pipeline fresh against the updated branch — a new invocation, not a continuation of the fixer's session, so nothing re-certifies its own prescription.
5. **Gate — loop or stop**: If the re-review has zero `auto-fix` findings, stop. If it has new ones and the round cap (3, see `pipeline/03-gate.md`) isn't reached, go back to step 2 with the new findings. If the cap is reached, stop and surface everything open.
6. **Final report**: Assemble the report — auto-fixed summary, then remaining findings in `REPORT-FORMAT.md`'s shape — and write the run record.

## Components

### Pipeline (`pipeline/`)

- **01-triage.md** — the action classifier: what's safe to fix without asking, what needs the author's judgment.
- **02-fixer.md** — the fix discipline: narrow, root-cause-first, never reverting intentional code, one commit per round.
- **03-gate.md** — the loop: when to stop, when to continue, and the ratchet exit ramp for fix rounds that overbuild.

### Templates (`templates/`)

`FIX-RUN-RECORD.md` — the audit record for one `review-fix` run. Not a living document like `.scan-state.json`; each run gets its own file.

## Notes

- **Never touches `code-review/`.** All classification and fix logic lives here, not in the lenses or the report format. Plain `review` behaves identically before and after `review-fix` exists.
- **Never runs against someone else's branch.** If asked to fix a PR you don't own, say so and point at plain `review` instead.
- **Never pushes.** Commits are local; the human decides when the branch is ready.
- **Bounded by default.** Three rounds. A branch that isn't converging after three rounds has a problem worth a human's attention, not more automated rounds.
