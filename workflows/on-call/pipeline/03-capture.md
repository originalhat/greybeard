# Phase 3 — Capture

Turn a concluded ticket into durable knowledge: a PHI-free audit entry, and — when the scenario was novel or an existing runbook was wrong/stale — a new or updated runbook. This is the step that makes the corpus self-improving. Run it after every ticket, even ones with no runbook impact (the audit entry still matters).

## Input

Ticket ID and the triage analysis / actual resolution (what the engineer really did, which may differ from what was proposed — capture what happened).

## Steps

### Phase 3a — Write the audit entry (always)

Write `../greybeard-data/output/on-call/audit/{YYYY}/{MM}/<TICKET-ID>.md` using `templates/audit-entry.md`. Create the `{YYYY}/{MM}` directory if needed (bucket by resolution date).

**This file must be PHI-free.** Record the *shape* of the problem and the fix, not the identifiers:
- ✅ ticket ID, date, repo(s), domain, ticket type, generalized symptom, root cause, the fix pattern (which runbook + generalized approach), risk, outcome, escalation contacts used (internal staff names OK).
- ❌ no member/dependent names, subscriber IDs, customer group numbers, UUIDs, emails, DOBs. If you need to refer to "the member," say "the member" — the ticket ID is the pointer to the real data in JIRA.

If the resolution differed from the proposal, record the difference and why — that's high-value signal for future tickets.

### Phase 3b — Decide the runbook impact

Classify the ticket against the existing corpus:

| Situation | Action |
|---|---|
| **Exact runbook match, worked as written** | No new runbook. Append the ticket ID to the matched runbook's **History** line and bump `last_verified`. |
| **Near match, needed adaptation** | Update the existing runbook: fold in the new wrinkle (a variant, an edge case, a gotcha). Don't fork a near-duplicate. |
| **Runbook was wrong or stale** | Correct it against current code. Note the correction in the runbook's Notes and in `.oncall-state.json`. |
| **Novel scenario** | Create a new runbook (Phase 3c). |
| **Self-service redirect** | Create/update a short runbook capturing the self-service path, so future similar tickets get the same redirect. |

When in doubt between "new" and "update an existing," prefer updating — the value is a tight, deduped corpus, not volume. Consult `INDEX.md` for the closest existing scenario before creating anything.

### Phase 3c — Create/update the runbook

Follow `context/RUNBOOK-AUTHORING.md` and `templates/runbook-scenario.md`. Key points:
- **One scenario per file**, short and self-contained. If it's growing past a screen or two, it's probably two scenarios.
- Place it in the closest **domain folder** under `runbooks/{repo}/{domain}/`. Check `INDEX.md` for precedent; don't invent a new folder without cause.
- **Generalize member examples** — use the `var = nil # fill in: …` convention; no real PHI.
- **Verify every code reference against the current code** in `../greybeard-data/sources/{repo}/` before writing it down. Record the repo SHA you verified against as `last_verified`.
- Cross-link related scenarios with relative links.

### Phase 3d — Update the INDEX and state file

- Add/refresh the scenario's row in `runbooks/{repo}/INDEX.md` (symptom keywords → file path).
- Update `.oncall-state.json`: the runbook catalog entry (path, domain, symptoms, `last_verified` SHA, related tickets) and the audit index (ticket ID → audit path, date, repo, domain).

## Guidelines

- The audit entry is mandatory; the runbook change is conditional. Never skip the audit entry.
- Keep the corpus deduped — updating beats forking.
- Never write a code reference you haven't verified against current source.
- PHI-free, always. The ticket ID is the bridge to the identifiable data.

## Next

Periodically run `curate` to keep the whole corpus healthy.
