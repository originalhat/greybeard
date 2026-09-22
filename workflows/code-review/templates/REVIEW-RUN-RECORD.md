# Review Run Record

The audit record for one plain `review` run. Written once, at step 11, to `$GREYBEARD_DATA/output/code-review/{repo}/runs/{YYYY-MM-DD}-{pr{n} | branch}.md`. In `--interactive` mode the draft-and-post loop appends to it.

The report is what the author reads and it lives in the thread. This file is what a later conversation reads when a finding was missed, demoted, or dropped and someone wants to know why, without reconstructing the review from a transcript. It mirrors `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/templates/FIX-RUN-RECORD.md`.

## Shape

```markdown
# Review Run — {repo} {#pr | branch}

**Repo:** {repo}
**Branch:** {branch}
**PR:** {url | none}
**HEAD SHA:** {sha}
**Base:** origin/main @ {sha}
**Run:** {ISO timestamp}
**Mode:** plain | interactive
**Lenses:** {LENS-A}, {LENS-B}, ... ({N})
**Agents:** {one per lens | {group}: LENS-A, LENS-B; {group}: LENS-C, … }
**Skipped lenses:** {LENS (reason), … | none}
**Context files:** {context/FOO.md, repo CLAUDE.md paths read in step 4b, or "none"}

## Findings

One row per finding raised in steps 5–6, before any filtering. Numbers match the report where the finding survived.

| # | Lens | Finding (one line) | file:line | Outcome | Why |
|---|------|--------------------|-----------|---------|-----|
| 1 | {LENS} | {consequence, one line} | {file:line} | kept | {one line} |
| 2 | {LENS} | {...} | {file:line} | demoted to nit | {one line} |
| – | {LENS} | {...} | {file:line} | dropped (8) | {fact-check: what did not hold} |
| – | {LENS} | {...} | {file:line} | dropped (8b) | {falsifier found: what recovers the user / which rule governs} |
| – | {LENS} | {...} | {file:line} | pre-existing | {why the branch did not make it newly reachable} |

Outcome vocabulary is fixed: `kept`, `demoted to nit`, `promoted` (nit raised to failure), `dropped (8)`, `dropped (8b)`, `pre-existing`.

## Falsifiers

For each finding that survived step 8, the fact that would have made it false and whether it was tested.

- #1: {falsifier} — searched {where}, not found
- #2: {falsifier} — could not test ({why: needs runtime, other repo not cloned, ...})

## Re-ranking

{Findings whose rank changed because a shared premise was dropped in 8b, or "none".}

## Cross-Repo

{clean | {repo}: {what was checked, what was found} | skipped ({why})}

## Tally

✅ {N} passed   ❌ {N} failed   ⚠️ {N} nits   · {N} pre-existing

## Interactive
{Only in --interactive mode. Appended as the loop runs.}

- #1 posted — {html_url}
- #2 dropped by user — {reason, one line}
- #3 reclassified pre-existing after author reply — {what the recovery path was}
```

## Notes

- **One file per run, never rewritten.** A second review of the same branch on the same day gets a `-2` suffix. The git history of the branch between runs is part of the record.
- **Every raised finding is listed, not just the survivors.** The dropped and demoted rows are the reason this file exists. A retro on a missed finding starts by checking whether a lens saw it and what step 8 or 8b did with it.
- **PHI-free.** No member identifiers, no test-data values, no PR description text. Findings are described the way the report describes them.
- **`deferred` is not in the vocabulary.** A finding the author should decide on is `kept`; it reaches the report (or `review-fix` triage as `ask-user`). Anything else is one of the drops, with the fact that killed it.
- **A cost-based `Why` is a formula.** Name N and write the cost in it (`N + N² vendor calls per launch, N = roster size`). A phrase like "one-time cost per item" cannot be checked and has hidden a quadratic fan-out before.
- **Written on every invocation**, including each round inside `review-fix` and the review inside `implement`. The fix-run record points at these files; it does not replace them.
- **Depth stays out.** One line per finding and one line per reason. The call path and full fix live in the thread, same as `REPORT-FORMAT.md`.
