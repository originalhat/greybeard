# Bulk Write Safety Reviewer

Detect set-based writes — `insert_all`, `upsert_all`, `update_all`, `delete_all`, `update_column(s)`, bulk-import gems, raw SQL — that bypass the ORM object lifecycle and silently drop guarantees the per-record path provided.

## Why This Matters

Replacing a per-row loop with a set-based write is the standard fix for a slow import, and the speedup is real. The cost is that these methods talk to the database directly: no model is instantiated, so **nothing that lives on the model runs**. Every guarantee the per-row path got for free must be re-established by hand, and each one that isn't is a silent gap — no exception, no log line, just wrong or invisible data.

Treat "we made the import 100× faster with `insert_all`" as a prompt to enumerate what the model did per record, and account for each item.

## What to Flag

### Validations Skipped
- A bulk write of user- or file-supplied data with no equivalent pre-check. Invalid rows are written, not rejected.
- A pre-check that covers *some* validations. Enumerate the target model's `validates`, custom `validate`, `belongs_to` presence, and DB constraints; each needs a counterpart or a reason it can't fire.
- A hand-rolled validation copy with nothing tying it to the model — a comment like "re-checks the validations `insert_all` skips" is a snapshot that will rot the next time someone edits the model. Prefer a shared validator/constant both paths call, or a spec that asserts the two agree.

### Callbacks Skipped
Walk the model *and its concerns* for every callback, then ask whether the bulk path needs it:
- `after_commit` / `after_save` — search indexing, cache invalidation, websocket broadcasts, downstream job enqueues, webhooks. Records exist but are invisible or stale in every derived system.
- Audit/versioning (`has_paper_trail`, `audited`) — no version row is written; the audit trail has a hole. A **hand-written version insert is its own red flag**: check the polymorphic `item_type` matches what readers query (namespaced/STI class names are a common mismatch), and that `object`/`object_changes` are populated if anything renders diffs.
- `before_save`/`before_validation` normalization, attribute defaults, enum coercion, `serialize`/`store` casting, encrypted attributes, counter caches, `touch:` on parents, and `created_at`/`updated_at` (not auto-stamped by all bulk methods).

### Ordering Creates Partial State
Set-based code splits one per-row operation into several passes. Flag when an earlier pass writes records for rows a later pass rejects — the per-row path would have skipped the row entirely, leaving nothing behind. **Validate and partition before the first write**, not between passes. Same question for a mid-loop raise: which passes already committed?

### Retry and Uniqueness
- Bulk-inserting join/link rows without `unique_by` or a DB unique index: a retried batch duplicates them. See `IDEMPOTENCY`.
- `delete_all`-then-`insert_all` reset patterns — both must be in one transaction, or a crash between them leaves the association empty rather than unchanged.
- `returning:` results are **not order-guaranteed**. Flag any code mapping returned ids back to inputs by array position; it must join on a natural key.

## Patterns

```ruby
# BAD: no validation, no callbacks, no audit row, partial state on reject
Address.insert_all(rows.map { |r| build_attrs(r) })

# GOOD: validate/partition first, then bulk write, then fire what the
# callbacks would have done — explicitly and in bulk.
valid, invalid = rows.partition { |r| AddressValidator.call(r).valid? }
report(invalid)
result = Address.insert_all(valid.map { |r| build_attrs(r) },
                            unique_by: :index_addresses_on_natural_key,
                            returning: %w[id natural_key])
SearchIndexJob.perform_bulk(result.rows.map(&:first))
```

## Severity

- **CRITICAL**: invalid data written past validations; audit trail gap on a regulated model
- **HIGH**: missing search/cache/broadcast side effects; partial state for rejected rows; ids mapped by position
- **MEDIUM**: missing timestamps or counter caches; duplicated validation logic with no drift guard

## False Positives to Avoid

- Models with no validations and no callbacks (pure join tables) — confirm by reading the model, not by assuming
- Bulk writes fed by already-validated, system-generated data
- Deliberately skipping callbacks where the code fires the equivalent in bulk afterward
- Backfills/migrations where the callbacks are intentionally suppressed and stated as such
