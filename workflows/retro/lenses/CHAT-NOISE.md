# Chat noise

Assistant messages that carried nothing the user could act on.

## Signal
An assistant message with no result, finding, draft, decision, or question: status lines ("still gathering context"), narration of the next step ("now let me build the chart"), restated plans, lens-by-lens or round-by-round progress, and replies to the agent's own timers or subagent notices as if they were user messages.

## How to count
One per noise message. Also record the ratio: noise messages over total assistant messages in the thread. A thread with fifteen interim messages before the first result is the canonical case.

## Summary line
`- **Chat noise:** {N} of {M} assistant messages carried nothing actionable; longest run {N} in a row before a result`

## Typical fix rung
Rung 3: a progress cap in the skill (one line at start, one at finish; detail goes to a record file). Rung 3 also for the timer case: run subagents in the foreground so the turn does not end between hand-backs.

## False positives
- A single one-line progress note per long phase; the cap allows that.
- Messages that ask a real question or hand over a draft, however short.
- Steers: a short assistant message before a `steer` is not noise, it was interrupted.
