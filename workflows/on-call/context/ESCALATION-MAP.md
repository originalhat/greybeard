# Escalation Map

Non-code escalation contacts and domain experts for on-call. Internal Sana staff names are allowed here (this file has no member/customer PHI). Keep it current as ownership shifts.

Two ways the triage phase finds who to talk to:
1. **Dynamic (per ticket)** — git-blame the affected files and pull assignees off similar resolved ER tickets. This is always done live in `pipeline/01-triage.md`; it stays accurate on its own.
2. **Static (this file)** — non-code contacts (finance, ops, vendor liaisons) that git blame can't surface.

## Non-code contacts

| Area | Who / team | When to escalate |
|------|-----------|------------------|
| Invoicing / business payments | _TODO: finance ops contact_ | Money movement, wire/check reconciliation, MT payment order questions |
| Broker & GA commissions | _TODO: finance ops contact_ | Commission disputes, external catch-up payments already made |
| COBRA administration | _TODO: COBRA ops contact_ | Vendor (CYC/Optum) transmissions, opt-in confirmation, election paperwork |
| Enrollment / eligibility ops | _TODO: ops contact_ | Retroactive terminations, OE period exclusions, EDI vs in-app method |
| Underwriting / policy | _TODO: underwriting contact_ | Reinsurance policy changes, plan-year extensions, rate corrections |

## Domain experts (code)

Prefer live git blame per ticket. This table is a fallback for areas that change hands slowly.

| Domain | Expert(s) | Notes |
|--------|-----------|-------|
| _TODO_ | _TODO_ | _Populate from recurring git-blame results and past-handler patterns._ |

> This is a stub. Populate it as the workflow runs — the `curate` phase can suggest additions from recurring escalation patterns seen in the audit log.
