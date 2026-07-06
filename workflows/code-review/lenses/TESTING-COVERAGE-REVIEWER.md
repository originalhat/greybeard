# Testing Coverage Reviewer

Identify gaps in test coverage, test quality issues, and tests that don't actually verify behavior.

## What to Flag

### Missing Coverage
- New functions/classes without corresponding tests
- Changed behavior without updated tests
- Error handling paths not tested
- Edge cases and boundary conditions untested

### Conditionally-Executed Code the Happy Path Never Runs
Code that only executes on **non-default data** is the most common thing to ship untested — it renders fine in every test, review click-through, and most real records because the branch was empty, then fires in production on the one record that populates it. Flag when new/changed logic lives inside:
- a block over a collection that is **empty** in all fixtures/factories (`collection.map { … }`, `.each`, `.select`)
- an **optional association** or nullable field being present (`if record.attachment.attached?`, `record.foo&.bar`)
- a **rare enum/state/flag** branch (`if status == :escalated`, feature-flag-on path)

For each, ask: **is there a test that actually populates the branch?** "It renders/returns fine" usually means the branch never ran. Require a fixture with a non-empty collection / present association / the rare state — not just a default-shaped record. This is how latent crashes (e.g. a route helper called inside a `.map` over attachments) survive review for weeks.

### Test Quality Issues
- Tests that only verify code runs, not correctness
- Missing or overly generic assertions
- Tests that pass even if implementation is wrong
- Testing implementation details instead of behavior

### Test Setup Problems
- Mocks that don't match actual behavior
- Tests depending on execution order
- Missing cleanup between tests (shared state)
- Hardcoded values that should use factories

### Timing Issues
- Race conditions in async tests
- Tests that use `sleep()` instead of proper synchronization
- Time-dependent code without time mocking
- Flaky tests due to timing assumptions

## Patterns

```ruby
# BAD: No assertion on actual behavior
it 'processes order' do
  process_order(order)  # Just checks it doesn't raise
end

# GOOD: Verify behavior
it 'processes order' do
  process_order(order)
  expect(order.status).to eq('processed')
  expect(PaymentAPI).to have_received(:charge).with(order.amount)
end
```

```python
# BAD: Time-dependent test
def test_expiry():
    token = create_token()
    time.sleep(2)  # Flaky!
    assert token.expired

# GOOD: Mock time
@freeze_time("2024-01-01 12:00:00")
def test_expiry():
    token = create_token(expires_at=datetime(2024, 1, 1, 11, 0))
    assert token.expired
```

## Severity

- **CRITICAL**: Core functionality untested, tests pass with broken code
- **HIGH**: Important paths untested, flaky tests
- **MEDIUM**: Edge cases untested, could use better assertions

## False Positives to Avoid

- Trivial getters/setters tested through usage
- Private methods tested via public interface
- Code covered by integration tests
- Refactoring without behavior change (no new tests needed)
