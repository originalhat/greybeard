# Validation Report Format

The canonical output format for the `validate` workflow. Written to `$GREYBEARD_DATA/output/validate/{repo}/{branch}-{timestamp}.md` and printed at the end of the run.

The reader wants to know **did it work, and if `--exploratory` ran, what else turned up** — in that order. Acceptance results are the verdict; exploratory findings are a bonus, clearly separated so a clean acceptance pass with an open exploratory bug doesn't read as an overall failure.

## Shape

```markdown
# Validation · {repo} {branch} · {ticket-id-or-"freeform"}

**Checked:** {ISO timestamp}
**SHA:** {sha}

✅ {N} passed   ❌ {N} failed   ⚠️ {N} couldn't verify

## Acceptance Criteria

1. {criterion} — ✅ pass
2. {criterion} — ❌ fail
   Expected: {what should have happened}
   Observed: {what actually happened}
   Steps: {action sequence that produced it}
3. {criterion} — ⚠️ couldn't verify
   Reason: {why}

## Exploratory Findings

{Only present when run with --exploratory.}

- **{severity}** {one-sentence description}
  Repro: {numbered steps}
  Scope: introduced by this change | pre-existing | unconfirmed

{Or, if none found: "Probed {categories} across {N} rounds. Nothing found."}

## Summary

{One or two sentences: overall verdict, and what needs human attention before this ships.}
```

Print the `## Exploratory Findings` section only when `--exploratory` ran at all — its absence on an acceptance-only run is expected, not an omission.

## Worked example

```markdown
# Validation · care_platform · feature/dark-mode-toggle · ER-1477

**Checked:** 2026-09-17T14:32:00Z
**SHA:** 8f2c1a0

✅ 3 passed   ❌ 1 failed   ⚠️ 0 couldn't verify

## Acceptance Criteria

1. Toggle in settings switches the app to dark theme — ✅ pass
2. Preference persists across reload — ✅ pass
3. Preference persists across login on a different device — ✅ pass
4. System-theme "auto" option follows OS preference — ❌ fail
   Expected: selecting "Auto" switches theme when the OS preference changes.
   Observed: theme stays on whatever it was when "Auto" was selected; no listener for OS-level changes.
   Steps: Settings → Theme → Auto → toggled OS dark mode via devtools emulation → app did not update.

## Summary

Manual light/dark/persistence all work. "Auto" doesn't actually track the OS — likely missing a `matchMedia` change listener. Worth a fix before shipping; the other three criteria are solid.
```

## Notes

- **Findings state what was seen, not a guess at the cause.** "Likely missing a listener" in the summary is a hint for the fixer, not a diagnosis this workflow verified — `validate` doesn't read the implementation, it drives the UI.
- **One file per run, never appended to.** A second `validate` run on the same branch (e.g. after a fix) writes a new timestamped file — the sequence of files is itself the record of convergence.
- **Severity vocabulary for exploratory findings is fixed**: `severe` (data loss, security-relevant, crash), `moderate` (wrong behavior, no data loss), `minor` (confusing but not incorrect).
