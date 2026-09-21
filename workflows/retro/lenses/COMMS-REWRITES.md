# Comms rewrites

Drafts meant for other people that the user rewrote before sending.

## Signal
The agent produced a message for someone else (PR comment or description, Slack reply, Jira comment, vendor email, ticket text) and the user changed it: shortened it, reframed it as a question, removed the fix mechanism, replaced plumbing with user impact, or wrote their own and asked for a proofread instead.

## How to count
One per draft rewritten. Classify the rewrite: `length`, `framing` (question vs. statement), `impact vs. mechanism`, `tone`, `wrong facts`, `replaced entirely`. Drafts the user posted as-is count as clean, and the ratio matters.

## Summary line
`- **Comms rewrites:** {N} of {M} drafts rewritten ({length: n, framing: n, mechanism: n, tone: n, facts: n, replaced: n}); …`

## Typical fix rung
Rung 3 when a skill produces the draft (the interactive review's voice rules and length ceiling are the model). Rung 5 for the user's global comms style when the same rewrite crosses skills; write it as examples of before and after, not adjectives.

## False positives
- Edits for facts the agent could not have known.
- The user adding content (a decision, a date) rather than changing what was there.
- Drafts explicitly requested as long-form.
