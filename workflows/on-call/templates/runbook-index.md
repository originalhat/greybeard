# On-Call Runbooks — {repo}

Router for on-call runbooks in `{repo}`. Each scenario is one self-contained file under a domain folder. The `triage` phase reads this file first to find a match before diving into code. Keep the symptom keywords good — they're how a novel ticket finds its runbook.

## Domain mapping

Domain folders loosely mirror the knowledge-extraction domains, but on-call tickets don't always map cleanly onto code-domain boundaries, so each scenario lives in its **closest operational home**. This table is the source of truth for where things go — check it before creating a new folder.

| Folder | Covers (operationally) | Nearest code domain(s) |
|--------|------------------------|------------------------|
| `accounts/` | User/identity, login, invitations, internal access, profile merges | accounts |
| `groups/` | Members, dependents, enrollments, COBRA/QLE, open-enrollment windows | groups, eligibility |
| `underwriting/` | Quotes, rates, insurance plans, reinsurance policy lifecycle | underwriting, digital-sales |
| `business-payments/` | Invoicing, disbursements, broker/GA commissions | business-payments |
| `shared/` _(cross-repo dir)_ | Scenarios spanning multiple repos | — |

## Scenarios

Grouped by domain folder. One row per scenario file.

### accounts
| Scenario | Symptom keywords | File | Last verified | Tickets |
|----------|------------------|------|---------------|---------|
| {title} | {keyword, keyword} | `accounts/{file}.md` | {date} | {ER-XXXX} |

### groups
| Scenario | Symptom keywords | File | Last verified | Tickets |
|----------|------------------|------|---------------|---------|
| {title} | {keyword, keyword} | `groups/{file}.md` | {date} | {ER-XXXX} |

### underwriting
| Scenario | Symptom keywords | File | Last verified | Tickets |
|----------|------------------|------|---------------|---------|
| {title} | {keyword, keyword} | `underwriting/{file}.md` | {date} | {ER-XXXX} |

### business-payments
| Scenario | Symptom keywords | File | Last verified | Tickets |
|----------|------------------|------|---------------|---------|
| {title} | {keyword, keyword} | `business-payments/{file}.md` | {date} | {ER-XXXX} |
