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
- **Pull latest** on the target repo clone: `git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" fetch origin && git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" checkout main && git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" pull`.
- **Read the runbook INDEX** at `$GREYBEARD_DATA/output/on-call/runbooks/{repo}/INDEX.md`.

### Phase 1b — Classify and match

Identify the **ticket type** — this sets investigation depth:
- **Ops data change** (update end dates, re-enroll member, extend plan) — look for a runbook match, generate a console script, minimal codebase exploration.
- **Data investigation** (discrepancy, reconciliation, "where is X") — query the relevant models, build diagnostic scripts.
- **Bug report** (errors, unexpected behavior, broken UI) — full codebase investigation, check recent changes, search past tickets. Consider `rollbar` (`mcp__rollbar__list-items` / `get-item-details`) for the error signature.

Then check the runbook INDEX for a matching scenario. **If there is an exact match, read that scenario file and go straight to the validation gate (Phase 1d)** — a runbook match does *not* let you skip validation; confirm the specific records are in the state the runbook assumes before recommending its fix. If a *near* match exists, read it as a starting point and adapt.

### Phase 1c — Investigate (parallelize where possible)

- **Search the codebase** in `$GREYBEARD_DATA/sources/{repo}/` — find related models, controllers, services, jobs. If the affected area is inside `domains/`, read that domain's `CLAUDE.md`. Cross-reference the knowledge-extraction domain record at `$GREYBEARD_DATA/output/knowledge-extraction/{repo}/domains/{domain}.md` for business-logic context.
- **Check recent changes** for the affected paths:
  - `git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" log --oneline --since="2 weeks ago" -- <paths>`
  - `gh pr list --state merged --search "<keywords>" --limit 5` (run from the repo clone)
  - If relevant, read the diff; note whether the fix is deployed or only on `main`.
- **Search similar past tickets** with `mcp__atlassian__searchJiraIssuesUsingJql` (`cloudId: "sanabenefits.atlassian.net"`). Build JQL from summary terms, e.g. `project = ER AND status = Done AND summary ~ "extend plan" ORDER BY created DESC`. Read the resolution (usually in the comments) of the top 2–3. If a match carries an `ER-*.md` attachment, download and read it.
- **Identify escalation contacts:**
  - Git expertise: `git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{repo}" log --since="6 months ago" --format='%an' -- <paths> | sort | uniq -c | sort -rn | head -5`.
  - Past handlers: the `assignee` of similar resolved ER tickets.
  - Static map: `context/ESCALATION-MAP.md` for non-code contacts (finance, ops).

Calibrate depth to ticket type. An ops change with a runbook match needs minutes, not an hour.

### Phase 1d — Validate the hypothesis with read-only snippets (REQUIRED before any data-change proposal)

By now you have a hypothesis about the root cause. **You must confirm it against the real records before recommending any change to data or state.** Do not skip this — a plausible-but-wrong hypothesis is how on-call turns one incident into two. A runbook match does not exempt you: verify the records are actually in the state the runbook assumes.

**You run nothing.** Assume the engineer runs every snippet and reports the output back. Your job is to hand over read-only snippets and wait. So:

- Write **one or more read-only snippets** that prove or disprove the hypothesis. Prefer **several small, focused snippets** over one big one when there are distinct things to confirm (does the record exist? what state is it in? what related records hang off it? does the guard condition actually hold?).
- Snippets must be **strictly read-only** — only queries, reads, and `puts`. No `update`/`create`/`destroy`/`save`/`!` mutators, no service-object calls with side effects, no writes of any kind. If you need a write to learn something, you're doing it wrong — find a read that answers it.
- **Make each snippet complete — don't offload lookups to the engineer.** Bake in every value you can derive: pull IDs, group numbers, and dates straight from the ticket; reuse values the engineer already reported from an earlier snippet; and chain lookups inside one snippet (find the record, then read its associations in the same script) instead of asking for an intermediate value. A snippet should be runnable as-is. Only leave a `# fill in` placeholder for a value that genuinely isn't known yet and can't be derived — and when that happens, prefer making a first read-only snippet that *discovers* it over asking the engineer to supply it. (This is the opposite of the generic runbook files, which keep `var = nil # fill in` because they're reusable and PHI-safe — here you're instantiating for one real ticket.)
- **One snippet at a time when they chain.** If a later check needs a value from an earlier check's output, send them sequentially: give the first, wait for the reported output, then give the next with that value baked in. Only batch snippets together when they're independent (none consumes another's output).
- Give **clearly-labeled `puts` output** so the reported result is unambiguous.
- **State up front what result confirms vs. refutes the hypothesis**, so the engineer's report back is decisive. Phrase it as "run this and tell me X" — never "let me check."
- **Wait for the reported output.** Only proceed to a proposal once the read-back confirms the hypothesis. If it refutes it, revise and validate again — loop here as many times as needed. Never present a data-change fix built on an unconfirmed hypothesis.

This gate applies hardest to **ops data changes** and **data investigations**, but validate before any bug fix that would touch data too. Pure "here's where the code is" answers with no data change are the only thing that can skip it.

### Phase 1e — Propose a solution

Only after the validation gate (Phase 1d) has confirmed the hypothesis.

**First, check for self-service.** If the reporter could resolve this themselves (admin UI, an ops/finance workflow, a documented non-eng procedure), push back: acknowledge the request, explain the self-service path with specific steps (screen, button, workflow), and offer to help if they hit issues. Be helpful, not dismissive. Then note it as a self-service redirect for the capture phase.

**If no self-service option exists,** lead with impact, not internals. The default output is a **short, plain-language summary** an on-call engineer or a non-eng stakeholder can act on in seconds — hold the deep technical detail back and offer to expand it. You still did the full investigation (Phases 1c–1d); this is about what you surface *first*, not what you know.

**Open with three tight parts (a few sentences total, no jargon):**

- **What's happening** — what the affected person experiences and can't do. ("A member's dependents can't see their invite cards, so they can't create accounts." Not "`registration_token` cooldown in `DashboardView`.")
- **Impact** — who and how many are affected, the member/business consequence, and urgency: blocking vs. degraded vs. cosmetic, one member vs. a whole group vs. systemic.
- **Recommendation** — the fix (or self-service path) in one plain sentence, whether it's low-risk, and whether you can do it now or need approval/input.

**Then go only as deep as the moment needs:**

- If the fix is a **data change**, hand over the read-only validation snippet(s) from Phase 1d (the human runs them), then the fix script — keep the framing plain even though the snippet itself is technical.
- **Offer the technical breakdown; don't dump it.** Close with a one-liner inviting expansion — e.g. *"Say the word for root cause, exact code paths, the console script, prior tickets, or who to loop in."* Expand a section only when asked, or when it's genuinely needed to execute the fix.

Keep this depth **ready on request** (only applicable ones — don't pad with "None found"):

- **Root cause** — the code-level why (file:line, service/method, the specific condition).
- **Affected area** — key files and modules.
- **Proposed fix (full)** — specific code changes with file paths and line numbers, or a console script. Make any console script **complete** — bake in values confirmed during Phase 1d rather than leaving `# fill in` placeholders — and keep the read-only preview / idempotent guard.
- **Runbook match** — the matched scenario file and any ticket-specific adaptation; note drift from current code.
- **Recent changes** — relevant commits/PRs; whether deployed or only on `main`.
- **Prior art** — similar past tickets and how they were resolved.
- **Risk assessment** — low/medium/high, what could go wrong.
- **Quick fix vs. proper fix** — if there's a tradeoff.
- **Who to talk to** — code experts (git blame) and past handlers.
- **Bugs surfaced** — genuine code defects noticed during investigation, distinct from this ticket's immediate fix (a guard that misfires, a hardcoded wrong value, a path that errors for anyone). Flag them so `capture` can log real defects to the **On-call bugs** Linear project.

## Guidelines

- **Lead concise and impact-first; go deep on demand.** Open with plain-language impact/UX and a recommendation an on-call engineer can act on in seconds. Keep root cause, code paths, scripts, and prior art ready but offer them rather than dumping them. Technical depth is available, not absent.
- **Confirm the hypothesis with read-only snippets before recommending any data change (Phase 1d) — this is non-negotiable.** Assume the engineer runs every snippet and reports back; you never run them yourself. Share read-only checks, wait for the output, then propose.
- Be specific — exact files, line numbers, methods.
- Don't propose changes to code you haven't read.
- If ambiguous, list the most likely interpretations and investigate the top one.
- If you can't find the root cause, say so and suggest diagnostic steps.
- **Don't assert operational details you haven't verified.** Schedules, cron cadence, worker triggers must be confirmed by reading the code — never assume something runs automatically. If you don't know, go check.
- **A runbook is a starting point, not a guarantee.** Spot-check the key code paths it relies on before recommending it; the codebase drifts. If you find drift, use the current code as source of truth and flag it for the capture phase.

## Next

Hand the analysis to the engineer for review. After they've acted, run `capture` to record it. If they want it on the ticket, run `publish` first.
