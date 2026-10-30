# Review-Fix Workflow

A loop-based auto-fix pipeline built on top of `code-review`. Where `review` stops at a report, `review-fix` classifies findings, applies the safe ones, commits them separately, and re-reviews with a fresh pass — bounded, and never on someone else's work.

## Directory Structure

```
review-fix/
├── AGENTS.md              # You are here
├── pipeline/               # 3-phase loop body
│   ├── 01-triage.md        # Classify findings by remedy scope
│   ├── 02-fixer.md         # Apply auto-fix findings, commit
│   └── 03-gate.md          # Re-review, loop control, ratchet exit ramp
└── templates/
    └── FIX-RUN-RECORD.md   # Audit record format for one run
```

Reuses, unmodified: `../code-review/lenses/`, `../code-review/context/`, `../code-review/templates/REPORT-FORMAT.md`, and the `review` pipeline itself (`../code-review/AGENTS.md`, and the global `review` skill). `review-fix` never edits lens or context files, and never changes what plain `review` outputs when run on its own.

## Inputs

Triggered by **`review --fix`** (current branch) or **`review --fix <branch> in <repo>`**. Optional **`--full`** forces a full review when the scope check would scope it.

- The current git checkout, under `$GREYBEARD_DATA/sources/{repo}/`. Unlike plain `review`, this is never a PR URL for someone else's fork — `review-fix` commits to the branch it runs against, so it only ever runs on a branch you can write to.
- Everything plain `review` needs: fetched `origin/main`, a three-dot diff, optional PR context.

## Outputs

- Local commits on the branch — one per fix round, kept separate from the author's original commits.
- A final report in `REPORT-FORMAT.md`'s shape, covering whatever `ask-user` findings are still open after the loop stops, prefixed with a short "Auto-fixed" table of what was resolved automatically.
- A run record at `$GREYBEARD_DATA/output/code-review/{repo}/fix-runs/{branch}-{timestamp}.md` per `templates/FIX-RUN-RECORD.md` — rounds run, per-round counts, commits created, final status. One-shot audit trail, not resumable state; there is no catch-up mode for this workflow.
- A plain review run record in `$GREYBEARD_DATA/output/code-review/{repo}/runs/` for **every round**, written by the `review` pipeline's step 11 exactly as a standalone `review` writes it. The fix-run record names each one. A fix-run record with no `runs/` files behind it means the rounds did not run the pipeline.
- Never a push. The branch stays local until the human pushes it.

## Execution

### Model Tiers

- **Initial review and every re-review:** unchanged from `review` — Sonnet for lens/context evaluation, Opus for fact-check.
- **Triage (Phase 1):** Opus — the remedy-scope classification is a judgment call, not pattern matching.
- **Fixer (Phase 2):** Sonnet — applies a pre-classified, narrowly-scoped set of fixes. One agent, one pass over all of that round's `auto-fix` findings together, not one agent per finding — fixes in the same file interact, and fixing them independently is how a fix loop starts contradicting itself.
- **Gate (Phase 3):** Opus — decides whether to loop, applies the ratchet exit ramp, assembles the final report.

### Steps

These steps are **strictly sequential** within a round; rounds run one after another, never in parallel.

0. **Scope check**: Run `../code-review/scripts/review-scope.sh {repo} {branch}` from the checkout (`REVIEW_BASE=origin/<base>` for a stacked branch). `reviewed <sha>`: HEAD is already reviewed; say so in one line and stop. `scoped <sha>`: every review in this run, the first and each re-review, is `review --since <sha>` with that same SHA, so the fixer's commits fall inside the delta. `full`, or `--full` was passed: review the whole branch. Print the script's reason line once.
1. **Initial review**: Run the standard `review` pipeline (`../code-review/AGENTS.md`, unmodified) against the current branch, scoped per step 0. This is exactly what plain `review` produces — same lenses, same context, same fact-check, same run record in `runs/`.
2. **Triage** (`pipeline/01-triage.md`): Classify every finding from step 1 as `auto-fix`, `ask-user`, or `no-op`.
3. **Fixer** (`pipeline/02-fixer.md`): If there are any `auto-fix` findings, apply them and commit. If there are none, skip straight to step 6.
4. **Gate — re-review** (`pipeline/03-gate.md`): Re-run the standard `review` pipeline fresh against the updated branch — a new invocation, not a continuation of the fixer's session, so nothing re-certifies its own prescription. A spec run, a full-suite run, or a read of the fixer's diff is not a re-review and does not replace one.
5. **Gate — loop or stop**: If the re-review has zero `auto-fix` findings, stop. If it has new ones and the round cap (3 for a full run, 2 for a scoped one; see `pipeline/03-gate.md`) isn't reached, go back to step 2 with the new findings. If the cap is reached, stop and surface everything open.
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
- **Every round leaves a `runs/` record.** The per-lens findings and what steps 8 and 8b did with them live there; the fix-run record is the loop's log and points at them. When a later calibration asks whether a lens ever raised something, this is where the answer is.
- **Bounded by default.** Three rounds for a full run, two for a scoped one. A branch that isn't converging has a problem worth a human's attention, not more automated rounds.
- **Stop when asked.** If the human says to stop, wrap up, or skip the review while a run is going, start no new agent and no new round. Let the agents already running hand back, write the fix-run record with status `stopped`, list what is still open, and say whether HEAD is unreviewed (a fixer commit with no re-review after it). On care_platform 2423, "let's wrap up the reviews" was followed by 9 more minutes of review.
