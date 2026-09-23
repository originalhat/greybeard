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
      "value": "high",
      "confidence": "high",
      "impact": {
        "before": "Every compound fetch or gh call is denied inside the sandbox and retried outside it.",
        "after": "Compound fetch and gh calls run on the first attempt; standalone ones are unchanged.",
        "verify": "gh api rate_limit | head -1 succeeds in a new thread; next retro counts 0 sandboxed gh or fetch failures"
      },
      "rollback": "git -C ~/workspace/agent-ops revert 378561a",
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
- `value` and `confidence` are `high` or `low` (see `pipeline/03-synthesize.md` step 6). Suggestions from before the 2x2 may carry `medium` confidence; read it as `low`.
- `impact` holds the Before, After, and How we'll know lines from `templates/SUGGESTION.md`; `rollback` is the one step that undoes the change.
- The file is committed with every change when `RETRO_HOME` is in a git repo.
