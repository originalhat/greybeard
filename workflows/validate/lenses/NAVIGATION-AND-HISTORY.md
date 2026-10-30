# Navigation and History

Real users don't follow the intended path. They use the back button, bookmark the middle of a flow, reload when unsure, and open everything in new tabs.

**Interfaces:** browser.

## Signals

The change adds a page or route, a multi-step flow, a modal, filters or tabs that should be remembered, URL parameters, or client-side state (drafts, selections).

## Moves

- **Back, forward, history:** step back and forward through the flow, including after the final submit. Watch for resubmit warnings, duplicate transactions, partial pages, and 404s.
- **Bookmark it:** copy the URL from the middle of a flow, or a filtered list, and open it in a fresh tab. Is the state restored, or plainly reset?
- **Reload** at every step of a multi-step flow.
- **Deep link:** paste the change's URLs straight into a fresh tab, including a mid-flow step and a record that doesn't exist.
- **Reverse:** accept every default to reach the end, then go back through each step and change the values. Do the changes stick, and does the summary update?
- **All the ways:** find every way to close, cancel, submit, and go back (the button, the X, Escape, a click outside, the browser back button, Enter). Use a different one each time.
- **Second tab:** open the same page twice and act in both.
- **Unsaved changes:** edit, then navigate away. Is there a warning? Is the draft kept or lost, and does that match what the user would expect?

## Findings

- Reload, back, or a bookmark loses work the user reasonably expected to keep.
- A deep link shows a blank page, a crash, or another record's data.
- Back after submit lets the user resubmit or reach a broken step.
- Different ways to close or cancel behave differently.
- The URL and the screen disagree (a filter shows active, but the list is unfiltered).

## False positives

- A flow that deliberately restarts on reload and says so.
