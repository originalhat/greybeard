# State

`$RETRO_HOME/state.json`. Read at the start of every run, written at the end of every run and every apply.

```json
{
  "lastRunAt": 1789747213000,
  "reviewedThreadIds": ["thr_…"],
  "suggestions": [
    {
      "id": "S-20260918-3",
      "category": "config",
      "ladder": 1,
      "target": "~/.claude/settings.json",
      "summary": "Exclude git push/fetch/pull and gh from the sandbox; allow the docker socket",
      "magnitude": "8/46 threads · 11 occurrences · 0 corrections, 2 steers · 11 failed commands · ~25 min lost",
      "effort": "small",
      "confidence": "high",
      "evidenceThreadIds": ["thr_…"],
      "status": "accepted",
      "proposedAt": 1789747213000,
      "reportDate": "2026-09-18",
      "lastEvidenceAt": 1789750000000,
      "resolvedAt": 1789760000000,
      "reason": "Applied as a settings change instead of the proposed AGENTS.md rule.",
      "commits": {"agent-ops": "378561a"},
      "ticket": null,
      "supersedes": [],
      "supersededBy": null
    }
  ]
}
```

## Status vocabulary

- `proposed`: in a report, waiting for the user. Fresh evidence attaches here.
- `accepted`: applied, or tracked by a ticket for large work. `reason` says what was actually done and how it differed from the proposal.
- `rejected`: the user said no. Keep their reason. **Never re-propose**; if the same pattern recurs, it goes in observations with a pointer to the rejected id.
- `deferred`: the user was not sure. Re-present only when `lastEvidenceAt` moves.

## Rules

- Ids are `S-YYYYMMDD-n`, unique forever; `n` restarts each day.
- `reviewedThreadIds` is a set. A thread is re-read only when its `updatedAt` passes `lastRunAt`.
- `commits` maps a repo nickname to the short sha, one entry per repo touched.
- The file is committed with every change when `RETRO_HOME` is in a git repo.
