# Corrections

Times the user told the agent it had something wrong.

## Signal
A user message that contradicts, reverses, or narrows what the agent just did or claimed: "we don't need a feature flag", "that's pre-existing", "on the right branch now", "I wouldn't say never", "this should apply only to production". Includes rewriting the agent's draft with different content, not just different wording.

## How to count
One correction per distinct thing the agent had wrong, even if the user said it twice. Quote the user's words, at most one line. Record what the agent had wrong in a few words. Do not count a new ask, a preference stated before the agent acted, or a steer sent mid-turn (see `STEERS`).

## Summary line
`- **Corrections ({N}):** "{user's words}" → {what was wrong}; "{…}" → {…}`

## Typical fix rung
Depends on the cause. Wrong assumption about the codebase → rung 3 (a check the skill runs) or rung 4 (memory). Overreach → rung 3. Judgment the user disagrees with → rung 5, written as a scoped default.

## False positives
- The user changing their mind after seeing the result ("actually, let's also…") is a new ask.
- Disagreements the agent turned out to be right about; note them under observations instead.
- Editorial rewording of a draft with the same meaning.
