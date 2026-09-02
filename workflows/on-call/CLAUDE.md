# On-Call Workflow

Triage and resolve engineering on-call tickets, and turn every resolution into durable, reusable knowledge — a hierarchy of short runbooks plus a PHI-free audit trail. The corpus improves itself: each ticket either matches an existing runbook or produces a new one.

## Purpose

On-call engineers field a stream of Engineering Request (ER) tickets — ops data changes, data investigations, and bug reports — mostly against `origami_claims` but also `care_platform` and `sana_mobile`. This workflow:

1. **Triages** a ticket: gathers context, classifies it, matches a runbook, investigates the code, and proposes a fix.
2. **Publishes** the reviewed analysis back to the live ticket (confirmation-gated).
3. **Captures** the resolution as a PHI-free audit entry and, when the scenario is novel, a new/updated runbook.
4. **Curates** the runbook corpus over time: keeps the hierarchy organized, dedupes, and re-verifies stale runbooks against the current code.
5. **Syncs** the runbooks into the app repo at the end of a shift via a branch + pull request (one-directional publish; the canonical store stays the source of truth).

## Relationship to the `origami_claims` `/oncall` commands

The `origami_claims` repo has its own `/oncall` and `/oncall-publish` slash commands that read `docs/runbooks/` **in that repo**. Those are left as-is — other engineers depend on them. This workflow is the **canonical, cross-repo, self-improving** home for on-call knowledge. Its runbooks and audit logs live in `$GREYBEARD_DATA` (see below), independent of any single app repo, because the app-repo clones are disposable and may eventually be consolidated.

## Data layout (source of truth)

Everything this workflow produces lives **outside this repo**, under `$GREYBEARD_DATA/output/on-call/`:

```
$GREYBEARD_DATA/output/on-call/
├── runbooks/
│   ├── origami_claims/
│   │   ├── INDEX.md                 # router: symptom/keyword → scenario file
│   │   ├── {domain}/                # domain folders mirror knowledge-extraction
│   │   │   └── {scenario}.md        # ONE self-contained scenario per file
│   │   └── ...
│   ├── care_platform/
│   ├── sana_mobile/
│   └── shared/                      # cross-repo scenarios
├── audit/
│   └── {YYYY}/{MM}/{TICKET-ID}.md   # PHI-free record of what on-call did
└── .oncall-state.json               # runbook catalog, last-verified SHA per file, audit index
```

Runbook code (models, services) lives in `$GREYBEARD_DATA/sources/{repo}/` — the cloned repos the other workflows use. Read code from there; write knowledge to `output/on-call/`.

### Domain hierarchy

Runbook domain folders loosely mirror the knowledge-extraction domains (`accounts`, `business-payments`, `eligibility`, `groups`, `underwriting`, …). On-call tickets don't always map cleanly onto code-domain boundaries, so each scenario goes in its **closest operational home**, and the per-repo `INDEX.md` documents the mapping. Keep it stable — when unsure where something goes, check the INDEX for precedent before inventing a new folder.

## Inputs

- A JIRA ticket URL (e.g. `https://sanabenefits.atlassian.net/browse/ER-1477`), a bare ER ticket ID, or a free-text problem description. The **`triage`** shorthand starts one.
- Read access to `$GREYBEARD_DATA/sources/{repo}/` (pull latest before investigating).
- The `atlassian` MCP (JIRA, `sanabenefits.atlassian.net`, project key `ER`). **Setup required** — see below.
- Optional: `rollbar` MCP for error-item investigation.
- The `Linear` MCP for logging surfaced bugs to the **On-call bugs** project.

## Outputs

- A triage analysis (proposed fix, risk, prior art, escalation contacts).
- A published JIRA comment + attachments (only on explicit confirmation).
- A PHI-free audit entry under `audit/{YYYY}/{MM}/`.
- New or updated runbook files, and an updated `INDEX.md` + `.oncall-state.json`.
- Linear bug tickets (confirmation-gated) in the **On-call bugs** project for genuine code defects surfaced during investigation.
- An end-of-shift branch + PR (confirmation-gated) publishing the runbooks into the app repo's `docs/runbooks/`.

## PHI / PII policy

**No member/dependent PHI or PII in any file this workflow writes.** Runbooks, audit logs, and Linear bug tickets stay generic; the JIRA ticket (BAA in place) is the pointer to real identifiers.

- Runbook console snippets use the `var = nil # fill in: …` placeholder convention — never hardcode real IDs.
- Audit entries record the *shape* of the problem and the fix, keyed by ticket ID — no member names, subscriber IDs, group numbers, UUIDs, emails, or DOBs.
- **Linear is not the BAA'd system JIRA is** — bug tickets there must be PHI-free too; describe the defect generically and link the JIRA ER ticket for the concrete case.
- **Internal Sana staff names are allowed** (escalation contacts, git-blame experts). The rule is about members/dependents/customers only.
- Generalize any real member example in a runbook unless a concrete example is genuinely necessary to explain the scenario.

See `context/RUNBOOK-AUTHORING.md` for the full authoring standard.

## Execution

Five verbs. Each maps to a pipeline stage. The first has a single-word shorthand (`triage`); the rest keep the `on-call` prefix.

### `triage <Jira ticket URL>`  (also `triage <ticket-id>` / `on-call triage <description> [in <repo>]`)
Run `pipeline/01-triage.md`. Gather context → classify → match runbook → investigate → **validate the hypothesis with read-only snippets** → propose. Read-only against production; produces an analysis, does not write to JIRA. **Before recommending any data change, the hypothesis must be confirmed with read-only snippets that the engineer runs and reports back** — this validation gate is required, and a runbook match does not skip it.

### `on-call publish <ticket>`
Run `pipeline/02-publish.md`. Confirmation-gated publish of the reviewed analysis back to the live ticket (comment + genuine artifacts).

### `on-call capture <ticket>`
Run `pipeline/03-capture.md`. Write the PHI-free audit entry; if the scenario was novel or an existing runbook was wrong/stale, create or update the runbook and refresh `INDEX.md` + `.oncall-state.json`. Also log any genuine code defects surfaced during triage to the **On-call bugs** Linear project (confirmation-gated, PHI-free).

### `on-call curate [<repo>]`
Run `pipeline/04-curate.md`. Housekeeping sweep: reorganize the hierarchy, merge duplicates, split overgrown files, and re-verify runbooks whose `last_verified` SHA is behind the repo's current `main`.

### `on-call sync <repo>`
Run `pipeline/05-sync.md`. End-of-shift: copy the canonical runbooks for the repo into its `docs/runbooks/` (preserving the domain hierarchy, non-destructive to the legacy flat runbooks), then open a branch + PR from the `$GREYBEARD_DATA/sources/{repo}` clone. Confirmation-gated; one-directional (canonical store → app repo).

## Components

| Path | Contents |
|------|----------|
| `pipeline/01-triage.md` | Gather → classify → match → investigate → propose |
| `pipeline/02-publish.md` | Confirmation-gated publish to JIRA |
| `pipeline/03-capture.md` | Audit entry + runbook create/update |
| `pipeline/04-curate.md` | Reorg, dedupe, freshness re-verification |
| `pipeline/05-sync.md` | End-of-shift branch + PR of runbooks into the app repo |
| `context/RUNBOOK-AUTHORING.md` | The authoring standard every runbook follows |
| `context/ESCALATION-MAP.md` | Domain experts and non-code escalation contacts |
| `templates/runbook-scenario.md` | Per-scenario runbook template |
| `templates/audit-entry.md` | Per-ticket audit entry template |
| `templates/runbook-index.md` | Per-repo INDEX router template |

## Setup: JIRA MCP for greybeard

This workflow needs the `atlassian` MCP available in the greybeard session the same way it is in `origami_claims` (cloud `sanabenefits.atlassian.net`, project key `ER`, ADF response format). It is **not yet configured here** — wire it up before running `triage`/`publish` against real tickets. Until then, `triage` can run on a pasted ticket description.
