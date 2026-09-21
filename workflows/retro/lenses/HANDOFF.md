# Handoff

Whether a thread ended in a state someone else, or a later session, could pick up.

## Signal
A thread whose outcome is `handed off`, `in progress`, or `stalled` and whose last assistant message is not a closing summary (what was done, what is left, where things are, what decision is pending). A later thread that opens with "continue from", "where were we", or re-derives state the earlier thread already had. Branches with unpushed commits and no note about them.

## How to count
One per thread that ended without a usable handoff, with what was missing. Separately, one per later thread that paid for it (minutes spent re-deriving).

## Summary line
`- **Handoff:** {clean | missing: {what}} · {N} min re-derived in {later thread} | n/a`

## Typical fix rung
Rung 3: the skill's closing summary template (what changed, what is open, where the branch is, next step). For threads ending on a question, the question itself should carry the state.

## False positives
- Threads that ended `done` with nothing to hand off.
- Threads the user closed abruptly; the agent did not get to summarize.
