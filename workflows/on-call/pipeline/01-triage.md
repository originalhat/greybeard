# Phase 1 — Triage

You are helping an on-call engineer triage and solve an engineering request ticket. This phase is **read-only against production** — it produces an analysis and a proposed fix, it does not write to JIRA or run any mutation.

## Input

A JIRA ER ticket ID (e.g. `ER-1477`), or a free-text problem description. Optionally a target repo (`origami_claims`, `care_platform`, `sana_mobile`); if unspecified, infer it from the ticket.

Fetch JIRA tickets with `mcp__atlassian__getJiraIssue` using `cloudId: "sanabenefits.atlassian.net"`, `responseContentFormat: "adf"`, and `"fields": ["attachment", "comment"]`. The Eng Requests project key is `ER`. Use ADF format to avoid inline image errors. If the fetch fails or the input already contains a description, proceed with what's available.

For relevant attachments (CSVs, spreadsheets, logs), download with:

```bash
curl -s -L -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" "<attachment_content_url>" -o /tmp/<filename>
```

**Prior analysis.** A previous run may have attached its analysis to the ticket as `ER-<TICKET-ID>.md` (via `publish`). If the ticket's attachment list contains such a file, download and read it **first** — it is the cross-engineer source of truth. Also check `audit/{YYYY}/{MM}/<TICKET-ID>.md` in the data dir for a prior PHI-free audit entry.

## Steps

### Phase 1a — Gather context (parallelize)

Run in parallel — they are independent:
- **Fetch the ticket** from JIRA.
- **Pull latest** on the target repo clone: `git -C ../greybeard-data/sources/{repo} fetch origin && git -C ../greybeard-data/sources/{repo} checkout main && git -C ../greybeard-data/sources/{repo} pull`.
- **Read the runbook INDEX** at `../greybeard-data/output/on-call/runbooks/{repo}/INDEX.md`.

### Phase 1b — Classify and match

Identify the **ticket type** — this sets investigation depth:
- **Ops data change** (update end dates, re-enroll member, extend plan) — look for a runbook match, generate a console script, minimal codebase exploration.
- **Data investigation** (discrepancy, reconciliation, "where is X") — query the relevant models, build diagnostic scripts.
- **Bug report** (errors, unexpected behavior, broken UI) — full codebase investigation, check recent changes, search past tickets. Consider `rollbar` (`mcp__rollbar__list-items` / `get-item-details`) for the error signature.

Then check the runbook INDEX for a matching scenario. **If there is an exact match, read that scenario file and skip to Phase 1d** — propose the runbook solution directly (but still do the code spot-check in Phase 1d). If a *near* match exists, read it as a starting point and adapt.

### Phase 1c — Investigate (parallelize where possible)

- **Search the codebase** in `../greybeard-data/sources/{repo}/` — find related models, controllers, services, jobs. If the affected area is inside `domains/`, read that domain's `CLAUDE.md`. Cross-reference the knowledge-extraction domain record at `../greybeard-data/output/knowledge-extraction/{repo}/domains/{domain}.md` for business-logic context.
- **Check recent changes** for the affected paths:
  - `git -C ../greybeard-data/sources/{repo} log --oneline --since="2 weeks ago" -- <paths>`
  - `gh pr list --state merged --search "<keywords>" --limit 5` (run from the repo clone)
  - If relevant, read the diff; note whether the fix is deployed or only on `main`.
- **Search similar past tickets** with `mcp__atlassian__searchJiraIssuesUsingJql` (`cloudId: "sanabenefits.atlassian.net"`). Build JQL from summary terms, e.g. `project = ER AND status = Done AND summary ~ "extend plan" ORDER BY created DESC`. Read the resolution (usually in the comments) of the top 2–3. If a match carries an `ER-*.md` attachment, download and read it.
- **Identify escalation contacts:**
  - Git expertise: `git -C ../greybeard-data/sources/{repo} log --since="6 months ago" --format='%an' -- <paths> | sort | uniq -c | sort -rn | head -5`.
  - Past handlers: the `assignee` of similar resolved ER tickets.
  - Static map: `context/ESCALATION-MAP.md` for non-code contacts (finance, ops).

Calibrate depth to ticket type. An ops change with a runbook match needs minutes, not an hour.

### Phase 1d — Propose a solution

**First, check for self-service.** If the reporter could resolve this themselves (admin UI, an ops/finance workflow, a documented non-eng procedure), push back: acknowledge the request, explain the self-service path with specific steps (screen, button, workflow), and offer to help if they hit issues. Be helpful, not dismissive. Then note it as a self-service redirect for the capture phase.

**If no self-service option exists,** present the findings. Include only applicable sections — don't pad with "None found":

- **Ticket summary** — one-line restatement.
- **Ticket type** — ops change / investigation / bug.
- **Affected area** — key files and modules.
- **Root cause** (if identifiable).
- **Recent changes** — relevant commits/PRs.
- **Runbook match** — the matched scenario file and any ticket-specific adaptation. Note any drift between the runbook and current code.
- **Prior art** — similar past tickets and how they were resolved.
- **Proposed fix** — specific code changes with file paths and line numbers, or a console script. Use the `var = nil # fill in` convention for any identifying values. Show the diff if straightforward.
- **Risk assessment** — low/medium/high, what could go wrong.
- **Quick fix vs. proper fix** — if there's a tradeoff.
- **Who to talk to** — code experts (git blame) and past handlers.

## Guidelines

- Be specific — exact files, line numbers, methods.
- Don't propose changes to code you haven't read.
- If ambiguous, list the most likely interpretations and investigate the top one.
- If you can't find the root cause, say so and suggest diagnostic steps.
- **Don't assert operational details you haven't verified.** Schedules, cron cadence, worker triggers must be confirmed by reading the code — never assume something runs automatically. If you don't know, go check.
- **A runbook is a starting point, not a guarantee.** Spot-check the key code paths it relies on before recommending it; the codebase drifts. If you find drift, use the current code as source of truth and flag it for the capture phase.

## Next

Hand the analysis to the engineer for review. After they've acted, run `capture` to record it. If they want it on the ticket, run `publish` first.
