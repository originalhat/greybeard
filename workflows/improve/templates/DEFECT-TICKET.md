# Defect Ticket

One Linear issue per defect the run found and didn't fix (`pipeline/05-finish.md` section 4). Lightweight: someone triaging the Defects project reads the title and the first paragraph and knows who is affected and how sure we are.

## Where

- **Project:** Defects (`https://linear.app/sana-health/project/defects-660ea7a5aebe`, team PROD). The project's default status, no assignee.
- **Labels:** `improve-workflow`, plus the repo's area label when the team has one (care_platform → `care-platform`). **No `Bug` label**: the project already says it's a bug.
- **Priority** by user impact: High when users lose data or a message, or a clinical workflow silently fails; Medium when users see a wrong or missing result with a workaround; Low for rough edges, wording, and accessibility gaps with an alternative path.
- **No relations** (blocks / blocked-by). When two tickets are the same underlying problem, mention the other ID in the description instead.

## Shape

```markdown
**Needs validation first:** {what to check, e.g. "run X in a CP staging console" or "reproduce in the browser"}. {Only when it rests on reading the code, low confidence, or an unrun check. Omit otherwise.}

{1-3 sentences in user terms: who hits it, what they do, what goes wrong. No code.}

{Optional: **Product question:** {the call someone has to make}, when it's unclear the current behavior is wrong.}

{Optional: **Steps:** a short repro, when validate reproduced it.}

+++ Agent notes

- Found by: improve {run id}, {I-n | validate {report path}}
- Where: `{path:line}`, …
- Evidence: {review-record / duplicate / test-gap / reading / validate repro}
- Seen on main @ {sha}

+++
```

## Rules

- **Title:** what the user experiences, not the code (`Refused referral status changes look like nothing happened`, not `422 dropped in useReferralStatus`). A product question can be phrased as one (`Should Escape and Enter cancel and save the title editors?`).
- **PHI-free.** Linear is not a BAA'd system. No member, patient, or provider names, IDs, DOBs, or production URLs. Describe data by shape.
- **One ticket per defect**, even when two rounds or validate found it twice.
