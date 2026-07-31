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

### Phase 3e — Log surfaced bugs to Linear (confirmation-gated)

If triage surfaced a **genuine code defect** — not an ops/data mishap, not a self-service gap, but a bug in the code that would misbehave for anyone hitting that path — file it in the **On-call bugs** Linear project so it enters the eng backlog. A ticket often has zero bugs; only log real defects, and dedupe against what's already there.

**Linear target (canonical IDs):**
- Project: **On-call bugs** — `646aaf4f-0cc9-4ac8-9b20-2f71c45f2318` (`https://linear.app/sana-health/project/on-call-bugs-660ea7a5aebe`)
- Team: **Product & Engineering** (key `PROD`) — `c67d5a14-45ce-4cb3-b5ac-03795f17fd2d`

**Steps:**
1. **Dedupe first.** Search the project for an existing issue: `mcp__Linear__list_issues` with `project: "646aaf4f-0cc9-4ac8-9b20-2f71c45f2318"` and a `query` of the defect's keywords. If it already exists, add a comment or link the new ER ticket instead of filing a duplicate.
2. **Draft the issue, PHI-free.** Linear is **not** the BAA'd system JIRA is — so the title, description, and repro must contain **no member/dependent PHI** (no names, subscriber IDs, customer group numbers, UUIDs, emails, DOBs). Describe the defect and repro generically (in terms of record shapes and code paths); put the concrete case behind the ER ticket link.
   - Title: a crisp defect summary.
   - Description (Markdown): what's wrong, the code location (`file:line`, service/method), a generalized repro, expected vs. actual, and a link to the source JIRA ticket (`https://sanabenefits.atlassian.net/browse/<ER-ID>`) for the specific case. Note a suspected systemic fix if one is known.
3. **Confirm before writing.** Show the engineer the drafted title + description and the fact that it'll be filed in On-call bugs. This is an external write — proceed only on explicit approval; let them edit first.
4. **Create it** with `mcp__Linear__save_issue` (no `id`): `team: "c67d5a14-45ce-4cb3-b5ac-03795f17fd2d"`, `project: "646aaf4f-0cc9-4ac8-9b20-2f71c45f2318"`, plus `title` and `description`. Report the created issue URL/identifier back.
5. **Record the link.** Add the Linear issue identifier to the audit entry (Phase 3a) so the ticket ↔ bug link is durable, and cross-reference it from the JIRA ticket in `publish` if that's being run.

If the JIRA/Linear write is unavailable or the engineer declines, note the surfaced bug in the audit entry anyway so it isn't lost.

## Guidelines

- The audit entry is mandatory; the runbook change and the bug log are conditional. Never skip the audit entry.
- Keep the corpus deduped — updating beats forking; dedupe Linear bugs against the project before filing.
- Never write a code reference you haven't verified against current source.
- PHI-free, always — in the audit log, the runbooks, **and** the Linear bug tickets. The JIRA ticket ID is the bridge to the identifiable data.

## Next

Periodically run `curate` to keep the whole corpus healthy.
