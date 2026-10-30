# Ecosystem

No feature lives alone. It depends on services, jobs, files, other apps, and the network. Each connection is a trust boundary: the other side may not follow the rules. Play "what if?" with each one.

**Interfaces:** any.

## Signals

The change calls an outside service or another internal app, enqueues or depends on a background job, reads or writes files, sends messages, receives webhooks or imports, or shows an error message.

## Moves

- **Map it.** From the change map's ecosystem, list each connection: what goes out, what comes back, and where a failure would surface.
- **What if it fails?** Make a dependency the change uses return an error or time out. In the browser, route the request through `browser_run_code_unsafe`. Locally, stub it or point it at a bad host. Then do the action. Can the user see what happened, retry, and keep their input?
- **What if it is slow?** Delay it past the app's timeout. Does the app wait forever, give up clearly, or act twice?
- **What if it sends something unexpected?** An empty response, a missing field, an unknown status, a duplicate webhook, or webhooks out of order.
- **What if the job never runs, or runs late?** Check what the user sees in the meantime, and after it catches up.
- **Around the front door.** Data can enter through imports, APIs, webhooks, admin tools, and jobs that skip the UI's checks. Push data that the UI would reject through each of those, then view it in the UI.
- **Server-side rules.** Submit input that passes the form but should fail on the server: a duplicate, a conflict, or a value that is out of range now.
- **Watch the logs.** Read the browser console and the local server log during every step. An error during the change's flow is at least a lead.

## Findings

- A failure leaves a spinner forever, a blank screen, or a false success message.
- The user's input is lost on error and must be typed again.
- An error message is technical, empty, or blames the user for a server problem.
- Data that enters around the UI breaks screens or rules the UI enforces.
- A late or duplicate outside event corrupts state.

## False positives

- Console or log noise that also appears on `main` on the same page and is unrelated to the change. Note it once as pre-existing.
