# Fix Run Record

The audit record for one `review-fix` run. Written once, at the end of the run, to `../greybeard-data/output/code-review/{repo}/fix-runs/{branch}-{timestamp}.md`.

Unlike `.scan-state.json` or `.campaign-state.json`, this is not read back in on a later run — there is no catch-up mode for `review-fix`. Each run is a one-shot loop against the branch as it stood when it started; the record exists so a human (or a later conversation) can see what happened without re-deriving it from git history.

## Shape

```markdown
# Review-Fix Run — {branch}

**Repo:** {repo}
**Started:** {ISO timestamp}
**Starting SHA:** {sha}
**Final SHA:** {sha}
**Status:** clean | capped | parked

## Rounds

### Round 1
- Findings from review: {N}
- Classified: {N} auto-fix, {N} ask-user, {N} no-op
- Fixed: {N}
- Commit: {sha short} — {one-line summary}
- Re-review result: {N} new findings | none — loop stopped

### Round 2
{...repeat per round actually run...}

## Ratchet Events

{One line per ratchet exit-ramp trigger, or "none".}
- Round {N}: {file}:{line} — reverted-to-minimal-fix recommended instead of further patching

## Final State

- {N} rounds run (capped at 3 | stopped clean)
- {N} findings auto-fixed total
- {N} findings still open, handed to the human in this run's report
- {N} commits created on the branch, none pushed
```

## Notes

- **One file per run, never appended to.** A second `review-fix` run on the same branch writes a new timestamped file, not a rewrite of the last one — the git history between runs is itself part of the record.
- **Status vocabulary is fixed**: `clean` (loop converged, nothing `auto-fix` left), `capped` (hit the 3-round limit with findings still open), `parked` (stopped early because every remaining finding was `ask-user` from round 1, nothing to loop on).
- **Commits, not diffs, are the record of what changed.** This file states *that* a fix happened and which commit it's in — the commit itself is the detail, same as `REPORT-FORMAT.md`'s rule that depth lives in the fix, not in what's printed.
