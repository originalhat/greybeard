# Repeated routine

Routine the agent does by hand that a skill or script should do, and skills or scripts that exist but did not run.

## Signal
Two shapes:
- **Gap:** the same sequence of commands or steps performed by hand in two or more threads (sync a skill, set up env vars, run the same four checks before a commit, fetch the same context). Nothing exists to do it.
- **Miss:** something exists to do it and was not used: a skill, a slash command, a script in the repo, a hook, an MCP tool. The agent did the work by hand, asked the user to, or skipped it. The `secrets` skill not used when a key was needed, `sync-local.sh` not run after a skill was added, `gh` used when the GitHub MCP was connected.

## How to count
One per routine per thread. For a gap: the sequence in a few words and where else it appeared. For a miss: what existed, where, and what happened instead. The cross-thread count is what matters; a gap in one thread is an observation.

## Summary line
`- **Repeated routine:** gap: {sequence} (also in {thread ids}); miss: {skill | script | hook} existed, {what happened instead}; … | none`

## Typical fix rung
Gap → rung 2 (a script or hook) or rung 3 (a step in the skill that owns that moment). Miss → rung 3 (the owning skill invokes the thing at the right step) or rung 2 (a hook so it cannot be skipped); a prose reminder is the wrong fix for a miss, since a reminder already existed and did not fire.

## False positives
- Routine that varies each time in a way that matters; that is judgment.
- A skill deliberately bypassed because it was broken or unavailable (note under `SYSTEM-NOTICES` instead).
- One-time setup.
