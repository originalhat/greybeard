# Follow the Data

Data entered in one place turns up in many others: lists, summaries, exports, emails, admin views, logs, and other systems. Changes leak into screens that were never part of the ticket. Follow a piece of data through its whole life and check every place agrees.

**Interfaces:** any.

## Signals

The change edits a shared component, a model or its columns, an API response, a status or enum, a calculation, an export or report, a message template, or anything more than one screen or system reads.

## Moves

- From the change map's **data paths**, visit every place the data shows up. If the map is thin, search the repo for other readers of the model, field, endpoint, or component.
- **Round trip:** create or edit through the changed screen or endpoint, then check the value in each place: list, detail, search, summary, export, print view, email, admin or staff view, the other party's view, and any downstream system you can see locally.
- **Reverse round trip:** change the same data from one of those other places, then come back.
- **Tricky data on the trip:** carry values from `INPUTS` (an apostrophe, an accent, a long name, a zero amount) through every place, including search and export.
- **Invert:** when the app can go both ways, go both ways. Export then re-import, or convert then convert back. A total should equal the sum of its parts. Results should agree.
- **Shared component:** visit two or three other pages that use a changed component and do their main action once.
- **Status and enum changes:** filter, group, and count by the new or changed value on lists and reports.

## Findings

- Two places show different values for the same thing.
- A place crashes, shows blank, or shows a raw value (an enum key, `null`, an ID, an HTML entity) for the new data.
- A shared change breaks a screen that was not part of the change.
- An export, report, or email leaves out or mangles the data.
- A round trip does not come back to where it started.

## False positives

- A place that deliberately shows a summary or an older snapshot. Look for wording that says so before reporting.
