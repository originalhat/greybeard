# External Integration Resilience Reviewer

Detect calls to another system (vendor API, sibling service, message broker) whose failure paths are unhandled, mis-handled, or handled in a way that costs the user more than the failure did.

Security of the integration is `EMBEDDED-INTEGRATION-SECURITY`. Repeated calls per item are `N-PLUS-ONE-QUERY`. This lens is about what happens when one call does not come back the way the code expects.

## What to Check, for Every New or Changed Remote Call

### The "vendor said no" path
- **404 or empty inside a multi-call lookup.** A loop that reads N items from the vendor and one read 404s: does the loop skip that item and continue, or does the exception end the whole lookup and report every remaining item as missing? A stale list plus one deleted member is the normal case, not the rare one.
- **4xx that means "no", not "broken".** 401/403/404/409/422 are answers. Retrying them is wrong, and swallowing them into the same bucket as a timeout hides a real problem behind a transient-looking one.
- **The caller can tell "no" from "unreachable".** If both surface as one error class or one metric tag, the on-call engineer cannot either.

### The "vendor unreachable" path
- Dropped connection, timeout, 502/503/504: retried, or failed on the first attempt?
- **Retry only what is safe to repeat.** A read can be retried. A write (POST, PATCH, PUT that is not idempotent by contract) may already have gone through; a retry can create a duplicate.
- **Retry count and where it is set.** Retries belong on the client, set at construction, not sprinkled at call sites. A client with hidden retries doubles every caller's worst case.
- **Retries inside a latency budget.** If the call runs on a request path with a deadline (a launch, a page load), a retry doubles the worst case for one call while the budget check happens elsewhere. Either the budget knows about the retry, or that path builds its client with none, and the code says which.

### Timeouts and budgets
- Connect and read timeouts are set, and set once: on the client or its construction, not as constants copied into every service that calls it. Two services with different copies of "the" timeout is a finding (see `OBJECT-DESIGN`).
- A synchronous path that makes K calls with timeout T has a worst case of K×T. Say the number. If a human is waiting, compare it to what they would tolerate.

### Partial success
- A loop that provisions or syncs N items and stops early (budget, error, break): does the caller know which items were done? Does the next run pick up where this one stopped, or start over from the same first item so the tail never gets processed?
- Work that reports success when the vendor answered but the local write did not happen, or the reverse.

### Job and webhook callers
- A job that wraps the call: which exceptions retry (transient) and which go straight to the dead set (permanent)? A "not found" that retries for a day is a wasted queue; a timeout that dead-letters on the first try is a lost event. See `JOB-CONFIGURATION`.

## Patterns

```ruby
# BAD: one stale member ends the whole lookup
ids.find { |id| client.member(id)['external_id'] == wanted }

# GOOD: a vendor "no" on one member is skipped, the lookup continues
ids.find do |id|
  client.member(id)['external_id'] == wanted
rescue Errors::NotFound
  false
end
```

```ruby
# BAD: every caller decides its own budget and retries nothing or everything
client.patients(auth: token, connect_timeout: 1, response_timeout: 2)

# GOOD: the client owns budgets and retry policy; the launch path opts out
client = Client.new(auth: token)             # defaults: short budgets, one read retry
launch_client = Client.new(auth: token, retries: 0)
```

## Severity

- **CRITICAL**: a write retried without idempotency; a permanent failure retried forever on a user-facing path
- **HIGH**: one vendor "no" aborts a multi-item operation; a retry inside a latency budget with no opt-out; timeouts absent on a synchronous path
- **MEDIUM**: "no" and "unreachable" indistinguishable to the caller or in metrics; budgets duplicated across callers
- **LOW**: a read that could retry once and does not

## False Positives to Avoid

- Calls already going through a client that owns timeouts, retries, and error classes, where the diff only adds a caller
- Jobs whose framework retries with backoff, when the exception classes are mapped correctly
- A deliberate "fail fast, next run heals it" design that the code or a comment states and a test covers
