# Counts and Position

Anything you can count, select, or put in order is a variable, and software is often written for "a few" of something. Zero, one, the last one, and all of them are where it breaks.

**Interfaces:** any. Lists, tables, searches, multi-selects, line items, API collections, batch jobs.

## Signals

The change shows or processes a collection: a list, a table, search results, line items, children of a record, a multi-select or checkbox group, permissions, tags, a batch, or a total or count.

## Moves

- **Zero, one, many:** make the collection empty, a single item, then many. Watch for "1 records found" and "0 result".
- **Zero on its own:** an empty set, a zero amount, or zero in a divisor. If there is a zero, something will try to divide by it.
- **Too few, too many:** fewer items than the screen or job expects (an invoice with no lines), then enough to page, then far more than typical.
- **Some, none, all:** select some options, none, and every one. Watch for none being treated the same as all.
- **Beginning, middle, end:** add, edit, delete, or move the first item, a middle one, and the last one. Deleting the last item is a frequent failure.
- **Sort order:** create items that should sort first and last. Check numbers sort as numbers (9 before 10), dates as dates, and names with accents or lowercase where a user expects them.
- **Paging:** go to the last page, delete its only item, and change a filter while on page 3. Check that totals match the rows across pages.
- **Depth:** for anything nested (folders, sub-items, threaded notes), go a few levels deeper than the seed data.
- **Empty states:** a new account, or a filter that matches nothing. Does the screen say what to do next, or look broken?

## Findings

- A count, total, or percentage that is wrong, off by one, or divided by zero.
- A plural that is wrong ("1 items").
- An empty, single, or very large collection that crashes, shows blank, or truncates without notice.
- None treated as all, or all truncated.
- The last item can't be deleted or moved, or the wrong item is acted on.
- Sorting or paging drops, repeats, or misorders rows.

## False positives

- Large-collection slowness under data far beyond any real account. Note the size you used.
