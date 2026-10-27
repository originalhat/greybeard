# Invariants Reviewer

Detect changes that can break a rule the code must always hold, in the small critical cores where one wrong value is costly: money, balances and quantities, date ranges, limits, and state machines.

Borrowed from formal methods: a human names the law, then something mechanical enforces it. Here the "something" is a guard, a DB constraint, or a test over many inputs, not a proof.

## When It Applies

The diff touches arithmetic on money or quantities, a balance or accumulator update, a date range, a cap or limit, rounding, or a status transition. Otherwise pass without comment.

## Step 1: Name the Laws

Write each law the touched code must hold as one sentence. Take them, in order, from:

1. The repo's own docs (root and domain `CLAUDE.md` / `AGENTS.md`)
2. DB check constraints, `NOT NULL`, and unique indexes
3. Model validations and state machine definitions
4. Assertions in existing specs
5. Method names and the shape of the calculation

Examples: "amount owed is never negative", "line items sum to the header total", "end date is on or after start date", "paid never exceeds allowed", "status only moves forward", "applied amount never exceeds the remaining limit".

Do not invent laws. A law the code implies but nothing states is a question for the author, not a failure.

## Step 2: Can the Diff Break One?

- Subtraction with no floor, division by a value that can be zero
- Rounding each line then summing, where the total is rounded once (sums drift by a cent)
- Floats for money instead of `BigDecimal` / integer cents
- `nil` treated as zero in one path and propagated in another; sums over an empty set
- Inclusive vs exclusive range ends, off-by-one at a limit, a timezone shifting a date
- Updating a component without recomputing the stored total derived from it
- A new transition that skips a state or moves backwards
- A guard removed, weakened, or moved after the side effect it protects

## Step 3: Is the Law Enforced, or Only True Today?

A law that holds only because the calculation is currently right breaks on the next change. Look for enforcement at the narrowest point before the value is persisted or used:

- A small guard: clamp when the law is a business cap, raise when a violation means upstream data is wrong (clamping bad input hides it)
- A DB check constraint where the database can express the law
- The same enforcement on every write path. Flag a new path that bypasses it: `update_column(s)`, `update_all`, `insert_all`, raw SQL, `save(validate: false)`, a second service that skips the callback

```ruby
# BAD: the law lives only in the arithmetic
def member_owes
  allowed_amount - plan_paid
end

# GOOD: the calculation proposes, the guard enforces
def member_owes
  (allowed_amount - plan_paid).clamp(0, allowed_amount)
end
```

```ruby
# BAD: skips the validation that enforces paid <= allowed
claim.update_columns(paid_amount: amount)

# GOOD: goes through the guard, backed by the DB
claim.update!(paid_amount: amount)
# add_check_constraint :claims, "paid_amount <= allowed_amount"
```

## Step 4: Is the Law Tested Across Inputs?

A law the diff touches deserves a test that checks it over many inputs, not one example. Suggest a property-based test (`prop_check` in Ruby, `fast-check` in TypeScript) or, at minimum, a table of boundary cases: zero, negative, the limit, the limit plus one, empty, `nil`, the first and last day of a range.

```ruby
G = PropCheck::Generators

it "never leaves the member owing a negative amount" do
  PropCheck.forall(G.nonnegative_integer, G.nonnegative_integer) do |allowed, paid|
    expect(Responsibility.new(allowed:, paid:).member_owes).to be >= 0
  end
end
```

Leave general coverage gaps to `TESTING-COVERAGE`; this lens owns tests of a named law.

## Reporting

Name the law in the consequence: "Breaks *paid never exceeds allowed*: a resubmitted claim can pay twice its allowed amount." Suggest the guard or constraint and the property to test in the fix.

## Severity

- **CRITICAL**: A money or balance law can be violated on a production path (wrong amount owed or paid, negative balance, limit exceeded)
- **HIGH**: The law is enforced on one write path but bypassed on another; a state can be skipped or reversed
- **MEDIUM**: The law holds today only because the calculation is right, with no guard, constraint, or test over inputs

## False Positives to Avoid

- Laws already enforced by a DB constraint the diff cannot bypass
- Values that legitimately cross the line: adjustments, reversals, credits, refunds. Check the domain before flagging a negative
- Display formatting and read-only reporting code
- Laws the diff does not touch, even if unenforced elsewhere (that is pre-existing)
