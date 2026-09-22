# Calibration Record

One ledger per repo at `$GREYBEARD_DATA/output/code-review/{repo}/calibration.md`, appended to by `review --calibrate <PR>` after a PR with human review has merged. Each entry compares the human review threads on one PR against what the pipeline's run records show it raised, and when.

The run record answers "why was this finding dropped". The calibration ledger answers "what do the humans catch that we do not, and is it the same thing every time". Repeated rows are what turn into a lens, a context entry, or a pipeline rule.

## Shape

```markdown
## {repo} #{pr} — {date merged}

**Reviewers:** {handles}   **Human threads:** {N} ({N} change requests, {N} questions, {N} nits)
**Run records:** {runs/… , fix-runs/… | none}
**Unreviewed pushes:** {N} — {sha short} ({what it added}, {lines}) …

| # | Reviewer | Thread (one line) | Pipeline | Bucket | Lens that should own it |
|---|----------|-------------------|----------|--------|-------------------------|
| 1 | {handle} | {what they asked} | {raised in run X and kept | raised, dropped (8b) because … | raised {N} min after the comment | never raised} | caught | found late | misjudged | never raised | not a miss | {LENS | context/FILE | none} |

**Tally:** {N} caught · {N} found late · {N} misjudged · {N} never raised · {N} not a miss

**Buckets by cause:**
- sequencing: {N} (pushes without a review between the last record and the push)
- lens gap: {N} — {LENS: what it did not ask}
- judgment: {N} — {what step 8/8b believed and why it was wrong}
- taste: {N} — {reviewer convention, candidate for REVIEWER-PRIORS}

**Proposals** (only when the ledger now shows the same lens or cause in two or more PRs):
- {LENS or file}: {one rule, one sentence}
```

## Bucket vocabulary

- `caught` — raised and kept in a run whose record predates the human comment.
- `found late` — raised and kept, but in a run after the human comment, or after the push the human reviewed.
- `misjudged` — raised, then dropped, demoted, or deferred, and the human was right.
- `never raised` — no run record mentions it.
- `not a miss` — the author defended it and the reviewer accepted; or the pipeline had it as a nit or pre-existing and that stood.

## Notes

- **Every human thread that asks for a change or questions behavior gets a row.** Approvals, thanks, and author replies do not.
- **PHI-free.** Threads are paraphrased; no member identifiers, no test-data values.
- **The "Lens that should own it" column is the point.** A row with `none` is a candidate for a new lens; a row naming a lens that exists is a candidate for a rule in that lens.
- **Proposals print, they do not apply.** Editing a lens or a context file is a change to what every future review does; it goes through the human, or through `retro` if one is running.
