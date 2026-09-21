# Repeated context

Context the user had to supply that the agent could have known or found.

## Signal
The user explains where something lives, what a term means, how the app runs, which environment to target, or what was decided earlier — and the same explanation appears in another thread, a memory file, a CLAUDE.md, or earlier in the same thread.

## How to count
One per distinct fact re-supplied. Record the fact in generic terms and where it was already written down, if anywhere ("in memory since Sep 10", "in CLAUDE.local.md", "nowhere").

## Summary line
`- **Repeated context ({N}):** {fact} (already in: {location | nowhere}); {…}`

## Typical fix rung
Nowhere written → rung 4 (memory) or the repo's `CLAUDE.md`. Written but not read → rung 3 (the skill reads that file at a specific step) or rung 2 (move the fact to where it is always loaded).

## False positives
- Context that changed since it was written; that is a stale doc, note it as such.
- Task-specific detail the agent could not have known (which ticket, which member scenario).
