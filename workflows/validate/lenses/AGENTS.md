# Lenses

Exploratory heuristics that are **generalized**: where to look and what to try. They are not tied to any one app. Per-app knowledge goes in `../context/`. Many are drawn from Elisabeth Hendrickson's *Explore It!* and its heuristics cheat sheet.

Each lens:

- Covers one area of risk.
- Names the **interfaces** it applies to: any, browser, API, or job. A lens that is browser-only is skipped for a change with no UI.
- Lists the **signals** in a change that make it worth running. The charter step skips lenses with no signal.
- Lists **moves**: concrete things to try.
- Says what counts as a finding, and names its false positives.
- Is under 60 lines.

## Available Lenses

| Lens | Interfaces | Looks for |
|------|------------|-----------|
| `INPUTS` | any | Values and formats: boundaries, malformed, pasted, international, hidden parameters |
| `COUNTS-AND-POSITION` | any | Zero, one, many; some, none, all; beginning, middle, end; sorting, paging, empty states |
| `ENTITIES-AND-CRUD` | any | Create, read, update, and delete every thing the change touches, in all the ways it can happen, with and without dependents |
| `STATES-AND-TRANSITIONS` | any | Statuses and lifecycles: every way between states, the transitions nobody designed, interrupting the in-between states |
| `TIMING-AND-REPETITION` | any | Double submits, concurrent edits, retries, rapid repeats, long waits, stale views |
| `FOLLOW-THE-DATA` | any | Everywhere the change's data turns up, and whether every place agrees |
| `ECOSYSTEM` | any | What if a dependency fails, is slow, or sends something unexpected; data that enters around the UI's checks |
| `ROLES-AND-ACCESS` | any | Other roles, no session, other accounts' IDs, some/none/all permissions |
| `NAVIGATION-AND-HISTORY` | browser | Back, forward, reload, bookmarks mid-flow, deep links, second tabs, unsaved changes |
| `SMALL-SCREENS-AND-KEYBOARD` | browser | Narrow viewports, keyboard-only use, zoom, focus, accessible names |

Lenses combine. The richest charters pair two: `ENTITIES-AND-CRUD` with `COUNTS-AND-POSITION` (delete a parent with zero, one, or many children), or `STATES-AND-TRANSITIONS` with `TIMING-AND-REPETITION` (act during the in-between state).

## Adding a Lens

1. Create `{AREA}.md` with an **Interfaces** line and the sections **Signals**, **Moves**, **Findings**, **False positives**.
2. Keep it under 60 lines and to one area of risk.
3. Add a row to the table above.
