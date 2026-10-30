# States and Transitions

Many bugs live in a short window: the moment between "saving" and "saved", or a status change that nobody expected from the current status. Map the states, then go where the map has gaps.

**Interfaces:** any.

## Signals

The change adds or touches a status, a lifecycle (draft, submitted, approved, paid, closed), a mode (editing, locked, suspended, expired), a multi-step process, or any wait between an action and its result (a spinner, a queued job).

## Moves

- **Find the states.** You have found a state when you can now do something you couldn't before, or can no longer do something you could, or the same action gives a different result. You have also found one whenever you would say "while…" ("while the claim is pending…", "while the import runs…"). A spinner is a state too.
- **Find the events.** These are the user actions, the system finishing something (a job or a callback), outside events (a webhook, a vendor response), and the passage of time (expiry, scheduled runs).
- **Make a table.** Put the states down the side and the events across the top. Fill each cell with what should happen. The cells nobody can fill are the charter: drive the app into that state and fire that event. Examples are canceling an approved item, editing during submission, and a job finishing after the user deleted the record.
- **All the ways.** For each transition, find every way to trigger it: the button, a bulk action, an API, a job, an admin override, a timeout. Check that each way has the same effects (notifications, audit, totals).
- **Interrupt.** During each in-between state, cancel, log out, reload, close the tab, let the session expire, or make the dependency fail. Afterward, is it back in a sensible state? Can the user start again? Was anything lost or half-written?
- **State variables.** Vary the previous state, how you got here, how many times you have been here (the second submission, the third retry), and how long you stayed.

## Findings

- A transition that should be blocked is allowed, or one that should work is blocked.
- An in-between state that, once interrupted, leaves a record stuck, half-written, or unrecoverable.
- Different routes to the same transition have different effects.
- The UI and the stored status disagree.

## False positives

- Transitions the intent explicitly forbids, when the app blocks them with a clear message.
