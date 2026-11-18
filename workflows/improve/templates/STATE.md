# State

`$GREYBEARD_DATA/output/improve/{repo}/state.json`. Read at the start of every run, written in step 3, step 4, `improve status`, and `improve reject`.

```json
{
  "repo": "care_platform",
  "nextId": 13,
  "visits": [
    {"path": "app/models/referral.rb", "sha": "8fbfd856cf63f3371f080dba2b5ecc019c9518af", "at": "2026-11-16"}
  ],
  "candidates": [
    {
      "id": "I-12",
      "title": "Status chips are built four ways",
      "fingerprint": "DESIGN-CONSISTENCY:client/src/Referrals/ReferralRow.tsx:ReferralStatus",
      "lens": "DESIGN-CONSISTENCY",
      "locations": ["client/src/Referrals/ReferralRow.tsx:40-62"],
      "consequence": "Each list draws its own chip, so colors drift and a new status needs four edits.",
      "fix": "Render ReferralStatus with the shared StatusChip.",
      "evidence": ["design-audit F-005", "duplicate: client/src/CareRequest/Status.tsx:12"],
      "label": "flagged",
      "kind": null,
      "userVisible": "Status chips in the referral list match the rest of the app.",
      "value": "high",
      "confidence": "high",
      "size": {"files": 2, "lines": 60},
      "pattern": "status-chip-implementations",
      "ref": "8fbfd856cf63f3371f080dba2b5ecc019c9518af",
      "slice": "slices/2026-11-16-client-src-referrals-referralrow.md",
      "status": "open",
      "branch": null,
      "commits": [],
      "run": null,
      "pr": null,
      "ticket": null,
      "reason": null,
      "createdAt": "2026-11-16",
      "resolvedAt": null
    }
  ]
}
```

A fresh file is `{"repo": "{repo}", "nextId": 1, "visits": [], "candidates": []}`.

## Fields

- `label`: `safe` | `flagged` | `out` (`pipeline/03-record.md` section 3). `userVisible` is set only for `flagged`.
- `kind`: for `out` only. `defect` (wrong behavior a user or caller hits) and `refactor` (structural work too big for a round) are filed in Linear at the finish; `restricted` (structural work in a restricted area) is not. `null` otherwise.
- `approach`: for `kind: refactor` only. `one-pr` (mechanical and behavior-preserving, however many files) or `campaign` (needs checkpoints; `pipeline/03-record.md` section 3).
- `run`: the run directory that last built or reopened it (`runs/2026-11-18-1`). `commits`: the SHAs of the round that built it.
- `ticket`: the Linear ID once filed (`PROD-2576`). A candidate with a ticket is never filed again.
- `value`: `high` | `medium`. Low-value candidates are never stored. `confidence`: `high` | `low`.
- `ref`: the `origin/main` SHA the candidate was last confirmed at. `pick-slice.sh` reads `visits[].sha` the same way: a file is skipped while it hasn't changed since its last visit.
- `pattern`: the `patterns.md` heading this candidate came from or advances, else `null`.

## Status vocabulary

- `open`: in the backlog. Step 4 may select it (unless `out`).
- `building`: a round started it. `branch` is set. A round that parks resets it to `open` with the reason, or relabels it `out` / `refactor` when it outgrew the gate.
- `built`: its round finished and passed the gate. `branch`, `commits`, and `run` are set, and `pr` once the run's draft PR opened.
- `merged`: its PR merged (set by `improve status`).
- `rejected`: the human said no, or its PR closed without merging. `reason` is kept. **Never proposed again** without new evidence that answers the reason.
- `stale`: the problem is no longer in the code. Reopened if a later slice finds it again.
- `too-big`, `campaign`: older entries only. Work too big for a round is now `out` with `kind: refactor` and an `approach`, and gets a ticket.

## Rules

- Ids are `I-{n}`, per repo, never reused.
- `visits` is append-only. The newest entry for a path wins.
- The file holds paths, symbols, and code only. Never member data.
