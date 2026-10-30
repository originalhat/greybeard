# Roles and Access

The change works for the person who built it. Does it behave right for everyone else? The app's existing access rules apply to every new feature, even when the ticket doesn't say so.

**Interfaces:** any.

## Signals

The app has roles, accounts, tenants, or logged-out pages, and the change adds a page, an action, an endpoint, a field, or data visible to more than one kind of user.

## Moves

- Repeat the core flow as each role `context/APPS.md` lists, especially the lowest-privilege role that can reach it.
- **Hidden is not blocked:** when a button is hidden for a role, open the URL or send the request anyway.
- **Other accounts:** change a record ID in the URL or the request to one that belongs to another account or member (local data only).
- **No session:** open the change's URLs, or call its endpoints, with no session or token, and with an expired one.
- **Some, none, all:** give a user some of the relevant permissions, none, and all. Check that none is not treated like all.
- **Role change mid-session:** if practical, lower a user's role, then act in their already-open session.
- **Follow access into the data paths:** lists, counts, search results, exports, and emails should not include records the role cannot open.

## Findings

- A user can see or change data they should not. Always `severe`. For member data, also a HIPAA standards finding.
- A user who should have access is blocked or sees an error.
- Counts, search, or exports reveal records the user cannot open.
- A visit with no session shows data or a broken page instead of a login prompt or a 401.

## False positives

- A role difference the intent explicitly describes.
- Access that matches the app's existing rules on sibling pages. Compare with a sibling before reporting.
