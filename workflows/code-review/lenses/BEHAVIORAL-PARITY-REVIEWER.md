# Behavioral Parity Reviewer

When a change adds a **second implementation of existing behavior** — a rewrite, an optimized path, a feature-flagged v2, a port — verify the new path is observably identical to the one it replaces, for the *bad* inputs as well as the good ones.

## When This Lens Applies

The diff adds a class/method duplicating logic that already exists; puts old and new behind a flag or env check; replaces a per-row loop with a set-based or vectorized equivalent; or moves logic between services/languages.

## Method

1. **Name the reference implementation** — the exact path being replaced. If the PR doesn't say, find it; you cannot review parity against an unnamed baseline.
2. **Enumerate its rejection and error behavior**, not its happy path: what does it raise, on what input, and what does the caller do with that?
3. **Find each counterpart in the new path.** Missing or different is the finding. Happy-path equivalence is the easy half and is usually already tested; the divergence lives in the error branches.

## What to Flag

### Raise → Coerce
The most common parity break: the old path failed loudly on bad input, the new one substitutes a default and continues.

```ruby
# OLD: unknown value is a hard error the caller surfaces to the user
Model.types.fetch(input)            # KeyError

# NEW: unknown value silently becomes the first enum member
Model.types[input] || 0
```

In the new path, every `|| default`, `.fetch(k, default)`, `rescue nil`, `&.`, `to_i`/`to_s` on unvalidated input, and `.presence || "fallback"` deserves the question *what did the old path do here?* A typo'd input that used to be a visible error now writes wrong data quietly — and there is no error to find it by later.

### Rejection Semantics Drift
Same rejection criteria, same *consequences* for a rejected item: does it now leave partial side effects the old path never created (see `BULK-WRITE-SAFETY`)? Is the error still reported to the same place, with the same identifying detail (row index, record id) that made it actionable?

### Normalization Drift
Trimming, casing, truncation, and phone/date/number parsing must match field-for-field. Two traps:
- **Inconsistent within the new path** — most fields get `.strip`, one doesn't. Silent, because the result is still a plausible-looking value.
- **Order matters** — truncate-then-trim ≠ trim-then-truncate (`" 85001".first(5)` → `" 8500"`). Normalize first, always.
- If the value also feeds a dedup or lookup key, drift additionally produces false-distinct records.

### Error Surface
Same exception classes reaching the same callers, same logging/alerting, same transient-vs-permanent retry classification. Converting a raise into a return value changes the caller's control flow even when the data is identical — see `JOB-CONFIGURATION`.

### Flag Rollout
- Default off, with the flag checked **per invocation** so it works as a kill switch (not memoized at boot or in a constant).
- Both branches exercised by specs. A dual-path PR whose tests only cover the new path has removed the regression net from the path still serving production.
- An explicit parity test: one fixture through both paths, asserting equal resulting state — **including invalid-input fixtures**, which is where divergence lives.
- A stated plan for deleting the old path. Two permanent implementations is the real long-term cost.

## Severity

- **CRITICAL**: silent data corruption on inputs the old path rejected
- **HIGH**: divergent rejection/error semantics; flag can't actually roll back; old path untested
- **MEDIUM**: normalization drift on non-key fields; no side-by-side parity test

## False Positives to Avoid

- Behavior changes the PR description states deliberately (read the description before flagging)
- Pure refactors where no second path is retained
- Divergence in internals only — query count, allocations, ordering of independent writes — with identical observable output
- Intentionally stricter new validation, where the PR accounts for the newly rejected inputs
