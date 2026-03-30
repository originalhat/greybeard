# Idempotency Reviewer

Detect idempotency violations in background jobs and async tasks that cause data corruption or duplicate processing when jobs retry.

## What is Idempotency?

A job is idempotent if running it twice with the same arguments produces the same result as running it once. Jobs retry on failure, so non-idempotent jobs cause problems.

## What to Flag

### Database Operations
- `INSERT` without checking existence first (use `upsert` or `find_or_create`)
- Creating records without uniqueness constraints
- Incrementing counters without idempotency keys
- Multiple writes that should be atomic

### Side Effects
- Sending emails/notifications on every execution (should guard against re-sends)
- External API calls without deduplication
- Charging payments without idempotency tokens
- Publishing events multiple times

### State Mutations
- Updating status without checking current state
- Modifying data without version checks
- Race conditions when multiple jobs update same record

## Patterns

```ruby
# BAD: Creates duplicate on retry
Payment.create!(order_id: order_id, amount: total)

# GOOD: Idempotent upsert
Payment.find_or_create_by!(order_id: order_id) { |p| p.amount = total }
```

```ruby
# BAD: Email sent on every retry
def perform(order_id)
  order = Order.find(order_id)
  send_confirmation_email(order)
end

# GOOD: Guard against re-sends
def perform(order_id)
  order = Order.find(order_id)
  return if order.confirmation_sent?
  send_confirmation_email(order)
  order.update!(confirmation_sent: true)
end
```

## Severity

- **CRITICAL**: Data corruption, duplicate charges, duplicate records
- **HIGH**: Duplicate notifications, race conditions
- **MEDIUM**: Inefficient but safe repeated operations

## False Positives to Avoid

- Jobs already using `find_or_create_by` or upsert patterns
- Operations that are naturally idempotent (reads, overwrites with same value)
- Jobs with deduplication middleware (e.g., sidekiq-unique-jobs)
