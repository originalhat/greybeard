# Timing and Repetition

Users are impatient, networks are slow, jobs retry, and two people edit the same thing. Speed, frequency, and duration are all variables.

**Interfaces:** any. Double clicks in a browser, repeated requests to an API, a job enqueued twice.

## Signals

The change adds an action that writes data or triggers a side effect (a save, a delete, a toggle, a payment, a message, a notification, a job), or adds loading states, polling, or a timeout.

## Moves

- **Double submit:** double-click the action, press Enter twice fast, or send the same request twice.
- **Back and resubmit:** submit, go back, and submit again.
- **Retry:** run the job, or replay the request, a second time with the same input. Retried work should not duplicate its effects.
- **Act while waiting:** click a second control while the first request is in flight, navigate away mid-save, or close the modal mid-save.
- **Slow responses:** delay the change's requests (`browser_run_code_unsafe` can route a request with a delay). Watch what the user sees, and whether controls stay clickable.
- **Faster than the screen:** type and act faster than the UI updates, the way a power user does. Edit a field and save before validation finishes.
- **Rapid repeats:** flip a toggle several times fast, then reload and see which state stuck. Hit an endpoint repeatedly and see how limits are reported.
- **Two actors:** edit the same record in two tabs or as two users, and save both. Delete it in one and edit it in the other.
- **Duration:** leave a form or a page open for a long time, then act. Watch for an expired session, stale data, or lost input.

## Findings

- A duplicate record, charge, message, or notification.
- The final saved state does not match the last thing the user did.
- The UI shows success for a request that later failed, or never shows the result.
- A stale view overwrites someone else's change with no warning.
- No loading feedback, so the user reasonably clicks again.
- A long wait loses typed input without warning.

## False positives

- Duplicates the server removes afterward, if no user or report ever sees them.
- Slowness only under artificial delays far beyond anything real.
