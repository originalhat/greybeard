# Skill follow-up

Skills and slash commands that ran and then needed manual patch-up.

## Signal
A `/skill` or trigger word ran (`review`, `implement`, `triage`, `validate`, `retro`, …) and afterwards the user or agent had to fix, redo, add, or remove something the skill should have handled: a missing prefix on posted comments, a draft PR that was not opened, a record not written, a step skipped.

## How to count
One per skill run, with the follow-up in a few words, or `ran clean`. If the same follow-up recurs for the same skill across threads, that is the strongest signal in this workflow.

## Summary line
`- **Skills used:** {skill} → {ran clean | needed: {what}}; {skill} → {…}`

## Typical fix rung
Rung 3: a step, flag, default, or record inside that skill. Never a prose rule elsewhere about a skill's behavior; fix the skill.

## False positives
- Follow-ups that are a new ask ("now also do X") rather than a gap in what the skill promised.
- Skills invoked for something outside their scope.
