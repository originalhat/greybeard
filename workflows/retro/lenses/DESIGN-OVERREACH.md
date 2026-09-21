# Design overreach

The agent built more, or bigger, than the ask.

## Signal
A feature flag where a removal was asked for; a new model where a column would do; an abstraction with one caller; real-time infrastructure for a display change; a two-hour implementation for a constants change. The user reacts with "we don't need…", reverts, or rewrites smaller.

## How to count
One per thread where it happened, with what was built versus what was asked, and the cost if visible (minutes, lines added then removed, review rounds spent on the discarded design).

## Summary line
`- **Design overreach:** {built} instead of {asked}; cost {N min | N lines reverted | N review rounds} | none`

## Typical fix rung
Rung 3: a design-choice step in the implementing skill that picks the smallest diff and reports the alternative as not built. Rung 5 only for repos where the "keep it simple" rule is not already written down.

## False positives
- Scope the user asked for explicitly, even if large.
- Necessary scaffolding (a migration for a column the ticket needs).
