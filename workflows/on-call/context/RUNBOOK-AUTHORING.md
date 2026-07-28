# Runbook Authoring Standard

Every on-call runbook follows these conventions. They're lifted from the `origami_claims` invoicing runbook — the format that proved out — and generalized for all repos. The goal: a coding agent can pick up any single runbook file cold and produce a specific, correct, actionable answer to a novel-but-related ticket.

## Audience: an agent, not a human reading top-to-bottom

Engineers rarely read runbooks directly. They ask a coding agent to combine the runbook with the live codebase and produce a situation-specific answer. So every runbook must carry enough context, code-level detail, and decision logic that an agent can reason from it without having read anything else.

Two consequences:
- **The engineer has not read this file.** Never reference it, quote it, or use shorthand defined in it ("Variant A", "Step 1b") when talking to the engineer. Communicate in plain, self-contained language. Class names, service objects, model attributes, console snippets, and UI paths are all fine — the engineer knows the codebase, just not this file's internal structure.
- **You may not have live data access.** If you need the current state of a record to choose a path, ask the engineer to look it up and report back. Be specific and directive: "Go to [location] and tell me [value]" — not "I need X so I can check Y." You are not doing the checking.

## One scenario per file, kept short

- Each `.md` file is exactly one scenario. If a file covers two distinct problems, split it.
- Aim for something an engineer can absorb in a couple of screens. Depth in the *fix* is fine; sprawl across *unrelated* scenarios is not.
- Cross-link related scenarios with relative links (`../accounts/shift-user-login.md`) instead of duplicating them.

## File structure

Use `templates/runbook-scenario.md`. The sections:

```
# {Scenario Title}

> Repo: {repo} · Domain: {domain} · Last verified: {YYYY-MM-DD} @ {repo short SHA}
> History: {TICKET-IDs}

**Symptom:** What the engineer / reporter observes.
**Root cause:** Why it happens — at the code level.
**Fix:** Step-by-step. Prefer the least-invasive path (see priority order below).
**Verification:** How to confirm it worked.
**Safety check:** How the fix respects the relevant invariants (see below).
**Notes:** Edge cases, gotchas, related scenarios, gotchas that bit us before.
```

Only include sections that apply — don't pad with "N/A".

## Clarify before you solve

Before presenting any fix, gather everything needed to give a specific, correct answer. List the information you'd need to actually execute — affected company/group, record IDs, current state, related records — and ask for all of it up front, in one batch. Ask first, then solve. Do not present a fix and then ask for clarification.

## Fix priority order (least-invasive first)

Work down this list; stop at the first option that fully solves the problem:

1. **Self-service / UI action** — a purpose-built internal-tools screen. Document exact screens, buttons, fields.
2. **Upstream record fix** — correct a record in another domain (enrollment, policy, coverage dates) and let the system re-derive. Document what to change and what downstream reprocessing fires.
3. **Console snippet** — a last resort. Must be minimal and surgical, include guard clauses that confirm the right records before any write, and be safe to run in production (no bulk updates without explicit IDs, no irreversible destructive ops).
   - Prefer direct model attribute updates when the change is simple; service objects add no value if they just wrap the same write — and their guards may be the very reason the UI failed.
   - Use a service object only when it carries meaningful logic (calculations, associations, side effects) you want to preserve — and confirm the same guard won't block you in the console.

## Console snippet conventions

- **Never hardcode identifying values.** Declare each at the top, set to `nil`, with a comment telling the engineer what to fill in:

  ```ruby
  group_number = nil  # fill in: e.g. "ABC123"
  period_start = nil  # fill in: e.g. Date.new(2026, 3, 1)

  company = Groups::Models::Company.find_by(group_number: group_number)
  # ...
  ```

- Include an **idempotent guard** where a re-run could double-apply.
- Show a **read-only preview** step before any write when the write is consequential.
- Remind the engineer to **save console output (PHI-scrubbed) to the ticket** for posterity.

## Verify against code before trusting the runbook

A predefined runbook is a starting point, not a guarantee — the codebase evolves and entries go stale. Before presenting a fix (especially from an existing runbook), spot-check the relevant service objects, model methods, controller actions, and UI wiring to confirm:
- The code paths you rely on still exist and behave as described.
- Guards/validations you route around are still in place and behave as expected.
- UI actions you reference still exist and hit the right endpoints.

If something is out of date, use the **current code as source of truth**, adjust, and flag the discrepancy for the capture/curate phase. Record the repo SHA you verified against in the runbook's `Last verified` line.

## Domain invariants (the "safety check")

Different domains have hard invariants a fix must respect. Spell out in each runbook how the fix honors the relevant ones. Examples:

- **Business payments:** money flows to the right place (everyone owed gets paid, everything owed lands on an invoice); history is never rewritten (correct via new adjustment/credit records, never by editing settled invoices/payments); the fix trues up across all three payment waves (customer invoicing → internal disbursements → broker commissions).
- **Enrollment / eligibility:** coverage dates and tiers stay consistent with what's billed; COBRA/QLE events transmit to the right vendor with the right qualified beneficiary.

When a runbook touches money or coverage, make the invariant check explicit — it's the difference between a fix and a new incident.

## PHI / PII

No member/dependent PHI or PII. Generalize examples; use the `nil # fill in` convention. Internal Sana staff names are fine. See the workflow `CLAUDE.md` PHI policy.
