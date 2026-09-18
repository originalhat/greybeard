# Phase 2: Summarize

One structured summary per thread, produced by subagents, in the shape of `templates/THREAD-SUMMARY.md`.

## How to run it

- Batch threads five to eight per subagent. Launch every batch in **one message** with `run_in_background: false`, so they run in parallel and the turn does not end until all are back. Background subagents make the thread go idle between hand-backs, which pings the user with half-finished status lines and breaks `bb thread wait`.
- Never read a full log into your own context. The subagent reads; you receive the summary.
- Give each subagent the summary template verbatim, the PHI rule, and the reading rules below.

## Reading rules for the subagent

Read the log twice, in two formats:

```bash
bb thread log <id> --format minimal --all      # the conversation, readable
bb thread log <id> --format json --all         # timestamps and event types
```

`--limit` is never acceptable here; it drops the start of long threads.

**Turns and steers.** In the minimal format a user message followed on the next line by `steer` was sent while the agent was still working. It is guidance, not a restart. A short assistant message right before a steer is a progress note, not an early end of turn. Only call something a stall if the turn visibly ended (a `Worked for` block closes, no tool activity follows, and the next user message is not a steer).

**Corrections vs. steers vs. new asks.** A correction says the agent got something wrong ("we don't need a feature flag", "that's pre-existing", "on the right branch now"). A steer adds guidance mid-turn. A new ask changes the task. Count them separately; only corrections and steers are friction.

**Tool failures.** Count each failed command or tool call once, and note whether it was retried and how (sandbox off, different tool, user did it by hand). A failure inside the sandbox that succeeded when retried outside is a *sandbox friction* event, not a broken tool.

**Timings.** From the json log: time from the first user message to the first substantive assistant result (not a status line); total wall time; time spent in the longest single turn; time between a user message and the agent's next output when the user was waiting on the agent. Round to the minute. Put `n/a` when the log does not support the number.

**PHI.** Describe situations, never values. "The first snippet would have printed member names" is fine. The names are not.

## What comes back

One `THREAD-SUMMARY` block per thread, concatenated. Phase 3 consumes them; the report never prints them whole.
