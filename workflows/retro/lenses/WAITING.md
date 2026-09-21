# Waiting

How long the user waited on the agent, and how long until the first real result.

## Signal
Timestamps in `bb thread log --format json --all` (`createdAt` on each event). A user message followed by a stretch of agent activity is time the user waited.

## How to count
- **First result:** minutes from the first user message to the first assistant message that carries a finding, a result, or a concrete question — not a status line or a statement of intent.
- **Total:** minutes from first user message to the last event.
- **Longest turn:** the longest single agent turn.
- **User waited:** sum of the gaps between a user message and the agent's next substantive output, across the thread.
Round to the minute. `n/a` when the JSON log is unavailable. Do not estimate.

## Summary line
`- **Timing:** first result after {N} min · total {N} min · longest turn {N} min · user waited on agent {N} min`

## Typical fix rung
Long first-result times with overreach → see `DESIGN-OVERREACH`. Long turns spent on the same failing command → see `TOOL-FAILURES`. Waiting with no cause in another lens is an observation, not a suggestion.

## False positives
- Time the agent spent on a task the user asked to be thorough about is not friction. Pair the minutes with what they bought.
- Gaps where the user walked away (a user message hours after the agent finished) are not waiting on the agent.
