# Phase 4 — Curate

A housekeeping sweep over the runbook corpus for a repo. Runbooks drift as the code changes and accrete as tickets pile up; this phase keeps the hierarchy tight, deduped, and verified. Run it periodically (e.g. after a batch of tickets, or on a cadence), not per-ticket.

## Input

A target repo (`origami_claims`, `care_platform`, `sana_mobile`). Reads `runbooks/{repo}/` and `.oncall-state.json`.

## Steps

### Phase 4a — Freshness re-verification

Pull latest on the repo clone, then find runbooks whose `last_verified` SHA is behind current `main`:

```bash
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" fetch origin && git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" checkout main && git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" pull
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" rev-parse HEAD   # current SHA
```

For each stale runbook, check whether the files/symbols it references changed since its `last_verified` SHA:

```bash
git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" diff --name-only <last_verified_sha> HEAD -- <paths the runbook references>
```

If referenced code changed, re-read it and reconcile the runbook against current behavior. Prioritize runbooks whose referenced paths actually changed — don't re-verify everything blindly. Update `last_verified` to the current SHA for each runbook you confirm or fix.

### Phase 4b — Dedupe and reorganize

- **Merge duplicates / near-duplicates** — two files describing the same scenario collapse into one; keep the union of gotchas and the combined History.
- **Split overgrown files** — a scenario file covering multiple distinct problems splits into separate files, cross-linked.
- **Re-home misfiled scenarios** — move files whose domain folder no longer fits; update `INDEX.md` and any inbound cross-links.
- **Fill hierarchy gaps** — if a domain folder has grown unwieldy, consider sub-grouping (and document the sub-grouping convention in `INDEX.md`).

### Phase 4c — Rebuild the INDEX and state file

- Regenerate `runbooks/{repo}/INDEX.md` so every scenario has a current row (symptom keywords → path, domain, `last_verified`, related tickets).
- Reconcile `.oncall-state.json` with what's actually on disk — no orphan entries, no missing files.

### Phase 4d — Report

Summarize for the engineer: runbooks re-verified, corrected, merged, split, or moved; any runbooks flagged as suspect but needing human judgment; coverage gaps noticed (domains or common ticket types with no runbook yet).

## Guidelines

- Prioritize by drift — re-verify the runbooks whose code actually moved first.
- Prefer a small, deduped, verified corpus over a large stale one.
- Don't silently drop a runbook; if you think one is obsolete, flag it in the report and let the engineer confirm before deleting.
- PHI-free throughout — the same rules as capture apply to anything you rewrite.
