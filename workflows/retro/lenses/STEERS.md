# Steers

Guidance the user sent while the agent was still working.

## Signal
In `bb thread log --format minimal`, a user message followed on the next line by `steer`. The agent had not ended its turn; the user added direction.

## How to count
One per steer message. Record the gist in a few words. A steer is **not friction on its own**; it is the tool working. It becomes evidence only when the same steer appears in two or more threads (the user keeps having to say the same thing) or when a steer corrects the agent's direction (count that under `CORRECTIONS` too).

## Summary line
`- **Steers ({N}):** {gist}; {gist}`

## Typical fix rung
Recurring steers about process ("use a monthly cadence", "run playwright") → rung 3 (a default or flag in the skill) or rung 4 (memory). Recurring steers about style → rung 5.

## False positives
- Treating a steer as evidence the agent stalled. It did not; the turn was still running. A stall needs a visible turn boundary with no tool activity after it and a non-steer user message.
- A short assistant message right before a steer is a progress note, not an early end of turn.
