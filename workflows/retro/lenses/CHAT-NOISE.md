# Chat noise

Assistant messages that carried nothing the user could act on.

## Signal
An assistant message that adds nothing new for the user:
- a status line that repeats one already given ("still waiting", "three agents left", "still running")
- a reply to the agent's own timer, background task, or subagent notice as if it were a user message
- two or more assistant messages in a row with no tool activity between them
- a restated plan

## How to count
One per noise message. Also record the ratio: noise messages over total assistant messages in the thread. A thread with fifteen interim messages before the first result is the canonical case.

## Summary line
`- **Chat noise:** {N} of {M} assistant messages carried nothing actionable; longest run {N} in a row before a result`

## Typical fix rung
Rung 3: run subagents in the foreground so the turn does not end between hand-backs.

## False positives
- One line before a tool step, when the next thing in the log is tool activity. The harness asks for these.
- Messages that ask a real question or hand over a draft, however short.
- Steers: a short assistant message before a `steer` is not noise, it was interrupted.
- JSON `agentMessage` items that carry a `parentToolCallId` are subagent output the user never saw ("Report delivered to the caller"). Count only the `── Assistant` blocks in the minimal log.
