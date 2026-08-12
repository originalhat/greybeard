# Concurrency & Locking Reviewer

Detect locks whose **scope**, **granularity**, or **failure mode** is wrong — held longer than the critical section, keyed more broadly than the actual contention, or silently not acquired.

## What to Flag

### Scope: Lock Held Beyond the Critical Section
A lock should wrap the smallest window that genuinely needs mutual exclusion — usually a read-then-insert on a uniqueness-sensitive table. Flag a lock wrapping a whole batch, request, or multi-step import: throughput drops to serial, and hold time now scales with input size.

```ruby
# BAD: lock spans parse, insert, and every downstream write for the batch
Model.with_advisory_lock!(LOCK) { import_slice(rows) }

# GOOD: lock only the find-or-create race
existing = Model.where(key: keys).index_by(&:key)
Model.with_advisory_lock!(LOCK) { insert_missing(keys - existing.keys) }
```

### Granularity: Key Too Broad
A single constant lock name serializes every caller globally, including tenants or records that could never collide. Prefer a key derived from what is actually contended (`"import-#{account.id}"`). Flag global constants where a scoped key is available — with a global key, concurrent unrelated work becomes a queue, and if the lock is non-blocking, the loser is dropped.

### Lock ⇄ Transaction Coupling
- Advisory locks taken `transaction: true` release at **COMMIT**, not at end of block — real hold time is the length of the surrounding transaction, not the block.
- Releasing *before* COMMIT lets another process observe pre-commit state. Pick one deliberately and say which in a comment.
- Any lock held across slow work inside the transaction (HTTP calls, large writes, file IO) → flag.

### Failure Mode: Silent Non-Acquisition
- Non-bang variants **return `false`** when the lock isn't acquired; an unchecked return means the work is silently skipped. Flag it.
- Bang variants raise — confirm the caller doesn't swallow it (see `JOB-CONFIGURATION`).
- Library footguns around block return values (e.g. a falsy block result read as "lock not acquired"). If the code needs a trailing `true` to behave, that semantics gap needs an explicit comment *and* a test, not just the workaround.
- No timeout → callers pile up waiting instead of failing fast.

### Missing Locks
- Read-then-write against a uniqueness rule with neither a lock nor a unique index. Pick one — a unique index plus retry is usually better than a lock.
- Two code paths creating the same resource where only one of them locks.

### Deadlock Shape
- Locks acquired in different orders across paths.
- Nested locks, or a lock taken inside a callback of another locked write.

## Severity

- **CRITICAL**: work silently skipped on lock failure; deadlock in a hot path
- **HIGH**: global lock serializing multi-tenant work; lock held across slow IO or a long transaction
- **MEDIUM**: missing timeout; over-broad key with currently low contention

## False Positives to Avoid

- Short locks around genuinely global invariants (sequence generators, leader election)
- Advisory locks guarding a cron job that is meant to run one-at-a-time
- Row locks (`with_lock`, `lock!`) on a single record for a brief update
- Locks the database already provides via a unique constraint the code correctly relies on
