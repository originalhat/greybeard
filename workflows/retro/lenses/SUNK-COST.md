# Sunk cost

The agent kept pushing a failing approach instead of stepping back.

## Signal
Three or more consecutive attempts at the same command, fix, or idea with the same class of failure; edits that patch the previous patch; the user saying "step back", "try a different approach", "this isn't working", or reverting the branch to an earlier point.

## How to count
One streak per approach. Record the approach in a few words, the number of attempts, the minutes from first attempt to abandonment or success, and how it ended: `succeeded`, `agent re-planned`, `user redirected`, `abandoned`.

## Summary line
`- **Sunk-cost streaks ({N}):** {approach} × {attempts} over {N} min → {ending}; …`

## Typical fix rung
Rung 3: a retry cap in the skill (after two failures of the same kind, stop, state the hypothesis that failed, and propose a different route before continuing). Rung 1 when the streak was a config wall the agent could not see (sandbox, auth); fix the wall.

## False positives
- Deliberate iteration the user asked for ("keep tuning until the test is green").
- Retries with different hypotheses each time; that is investigation, not sunk cost. The signal is the *same* failure repeating.
- A streak that succeeded on the third try in under five minutes.
