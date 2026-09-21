# Manual steps

Things the user did by hand that the agent could have done, or that a script could.

## Signal
The user reports doing something themselves: running a snippet and pasting output, adding keys to an env file, creating a ticket, relinking a file, restarting a session, switching a branch, running a sync script.

## How to count
One per distinct manual action. Say what it was in a few words and whether the agent asked for it or the user volunteered it. Running a read-only console snippet the agent asked for counts once per round trip.

## Summary line
`- **Manual steps by the user ({N}):** {action} ({asked | volunteered}); {…}`

## Typical fix rung
Rung 2: a script, a hook, an automation, a template for the snippet. Rung 1 when the step exists only because of a sandbox or permission boundary that config could move.

## False positives
- Steps that are the user's by design: running anything against production, approving a PR, sending a message to a person, entering a secret.
- A one-time setup the agent could not have done (OAuth in an interactive session).
