# Unverified claims

Results the agent asserted without having produced them.

## Signal
A statement of outcome with no matching command or tool call before it in the same turn: "this reproduces", "tests pass", "the page renders", "the migration is safe", "X is already handled by Y". The user asking "did you actually run it?" or "were you able to reproduce?" is the loudest form. Also: tests written after the code they cover, or a test suite named as passing with no run in the log.

## How to count
One per claim. Record the claim in a few words, whether the user caught it, and whether it turned out true, false, or unknown. A claim later shown false counts under `CORRECTIONS` as well.

## Summary line
`- **Unverified claims ({N}):** "{claim}" → {caught by user | uncaught} → {true | false | unknown}; …`

## Typical fix rung
Rung 3: the skill that made the claim gets a step that produces the evidence before the claim (run the repro, load the page, run the suite) and prints what it saw. Rung 5 only for free-form work outside any skill.

## False positives
- Claims explicitly marked as untested ("I have not run this; expect…").
- Facts read from code or docs, cited with the file. Reading is verification for a claim about what code says; it is not verification for a claim about what code does.
- Results the user asked the agent not to verify ("skip the browser check").
