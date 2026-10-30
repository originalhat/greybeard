# Entities and CRUD

Software exists to manage things: members, claims, visits, notes, plans. Create, read, update, and delete each thing the change touches, in every way the app allows, and see what happens to the things connected to it.

**Interfaces:** any.

## Signals

The change map lists entities: the change adds a model or columns, a form that saves something, an endpoint that writes, a bulk action, an import, or a job that creates or updates records.

## Moves

- **Find the less obvious entities.** Any form that saves creates or updates something. A session, a draft, an assignment, and an audit entry are entities too.
- **All the ways to CRUD.** List every route that creates, edits, or deletes the entity: the main form, an inline edit, a bulk action, an import, an API, a job, a side effect of another action, undo. Do the same change through each route, then compare the results. Records created by the system (a job, a webhook) often skip what the user path does.
- **CRUD with data variations.** Create with every optional field filled. Update by clearing them. Update one field and check that the others didn't change.
- **Zero, one, many dependents.** Create a record with no children, one, and many. Delete the parent in each case. Are the children removed, orphaned, or blocking? Can you still open the children's pages?
- **Reassign.** Move a child to a different parent, and check both parents' counts and views.
- **Delete and come back.** Delete something, then use a link, a recent-items list, a notification, or another tab that still points to it.
- **Audit and history.** If the app keeps history or an audit trail, check that every route above writes it, including bulk and imported changes.

## Findings

- One route to create or update gives a different result than another (missing fields, no audit entry, no notification).
- A cleared field keeps its old value.
- An update changes fields the user didn't touch.
- Deleting a parent leaves orphans, breaks child pages, or deletes more than the user was told.
- A record can be created that violates a business rule the UI normally enforces.

## False positives

- Differences between routes that the intent describes, like an import that skips notifications by design.
