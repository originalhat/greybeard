# Query Efficiency Reviewer

Find database and computation work that grows with data or traffic and doesn't need to: the cost behind a slow endpoint or job that isn't an N+1. N+1s belong to `N-PLUS-ONE-QUERY`; this lens covers everything else on the request path.

## The Core Test

Flag only when you can name **all** of these:

1. **The path:** the endpoint, job, or render that runs this code, and roughly how often (every page load, a polled count, once a night).
2. **What grows:** rows loaded, queries issued, bytes serialized, or work repeated, as a function of something real (`N = open care requests for the queue`, `N = messages in the thread`).
3. **The cheaper equivalent** that returns the same result.

"This could be slow" without a path and a growth term is not a finding. When production APM evidence is given (p95, hits), tie the finding to that endpoint.

## What to Flag

### Loading more than the answer needs
- `.count` / `.size` / `.any?` / `.present?` on a relation that loads every row, when `exists?` or a SQL `COUNT` answers it.
- `.all` or an unscoped association iterated to filter, sort, sum, or group in Ruby when SQL can (`where`, `order`, `sum`, `group`, `pluck`).
- Whole records loaded to read one or two columns (`map(&:id)` where `pluck(:id)` or `ids` works).
- Large text, JSON, or blob columns loaded for a list view that never shows them (`select` the columns the view uses).
- No `limit` or pagination on a list that grows without bound.

### Queries the database can't do cheaply
- `where` or `order` on columns with no index, on a table that grows. Check `db/schema.rb` or `structure.sql` before flagging; a composite index whose leading column matches covers it.
- `LIKE '%term%'`, `lower(column)`, or a function on the column in a hot `where`, with no matching index.
- `OR` across columns, or `NOT IN (subquery)` on large tables, where a `UNION` or `NOT EXISTS` is the cheaper equivalent.
- Counts recomputed on every request for data that changes rarely, when the app already has a cache or counter pattern (`map.md` or the repo's docs say which).

### The same work twice
- The same query issued more than once per request (the same scope built in a controller and again in its presenter or serializer).
- An association loaded, then queried again through a fresh scope (`record.items.where(...)` after `includes(:items)`), which bypasses the preload.
- Serialization that walks the same associations once per field.

### Polling and broadcast fan-out
- An endpoint the client polls on a timer (sidebar counts, badges) that runs several counts per call, when one grouped query returns them all.
- A broadcast that re-renders or re-queries the full payload for every subscriber when only one record changed.

## Do Not Flag

- Anything bounded by a small constant (`N ≤ 10` statuses, one record by id).
- Cold paths: admin-only pages, one-off scripts, rake tasks, unless APM shows them hot.
- Caching proposals with no invalidation story. A cache is a behavior change: stale data is a bug.
- Index proposals on tables without the growth term, or that duplicate an existing index.
- N+1 patterns (`N-PLUS-ONE-QUERY`) and React render cost (`REACT-PERFORMANCE`).

## Suggesting the Fix

Give the cheaper equivalent as code, and how to prove it: the query count or rows loaded before and after, for one request with a realistic N. A new index is a migration, so it is a ticket, not an inline fix.
