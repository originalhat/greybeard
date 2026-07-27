# Testing Coverage Reviewer

Identify gaps in test coverage, test quality issues, and tests that don't actually verify behavior.

Unlike a pattern-scan lens, this is a **join**: you cannot judge coverage by sweeping the diff once. Work the method below in order — enumerate first, *then* judge — or you will silently skip changed units you never got around to. That omission is the failure mode this lens exists to prevent (see `onSuccess: closeModal` in the callback section).

## Method

Do these three passes **in order**. Do not start judging tests until enumeration is complete.

1. **Enumerate** — list every changed hunk that introduces or changes **runtime behavior**. Include new/changed functions, branches, callbacks, and handlers. Exclude pure refactors, renames, type-only changes, comments, and formatting. This list is your checklist; every item gets a verdict.
2. **Locate** — for each enumerated unit, find the test that covers it (search test files by symbol/behavior, not just "was a test file touched"). If none exists, the verdict is a coverage gap.
3. **Judge** — for each located test, apply the criteria in *What to Flag*: does the path actually execute (not an empty collection / unfired callback), and does it assert the **observable outcome** (not just dispatch)?

Emit a coverage table so nothing is dropped, then detail the failures:

| Changed unit | Covering test | Verdict |
|--------------|---------------|---------|
| `onSendToProvider` success path | `useLabFilesController.test` — asserts dispatch only, never fires `onSuccess` | FAIL — no success-outcome assertion |
| `discardFromModal` | `"discards the report…"` — fires success, asserts modal closed | PASS |

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

### Async Success/Error Callbacks the Mock Never Fires
The other half of "looks tested but never ran": logic inside a **callback passed to an async caller** — `mutate(args, { onSuccess, onError })`, `.then/.catch`, `resolve/reject` handlers. A bare-spy mock (`jest.fn()`) **swallows those callbacks and never invokes them**, so the callback body (`closeModal`, `showSnackbar`, a redirect, a state reset, cache invalidation) is dead code to the test — it can be missing, wrong, or renamed and the test stays green.

The giveaway is a test that stops at **dispatch** (`expect(mutate).toHaveBeenCalledWith(...)`): that proves the request fired, not that anything happens on success or failure. For every handler passing `{ onSuccess, onError }` (or `.then/.catch`), ask: is there a test that **fires the success callback** (`mockImplementation((_a, opts) => opts.onSuccess?.())`) and asserts the **observable outcome** (modal closed, snackbar shown, state reset), plus one that fires the **error callback**?

**Check sibling handlers for asymmetric coverage.** When several handlers share the same `{ onSuccess, onError }` shape, coverage should be symmetric — if one has a success-outcome + error test but a new/changed sibling only asserts the dispatch, that asymmetry is exactly how a dropped `onSuccess: closeModal` ships green.

### Test Quality Issues
- Tests that only verify code runs, not correctness
- **Asserting dispatch instead of outcome** — `expect(spy).toHaveBeenCalledWith(...)` on a mutation/request/dispatch proves the call was *made*, not that the resulting behavior (state change, UI update, side effect) is correct. Require an assertion on the observable result.
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

```tsx
// BAD: mock swallows { onSuccess, onError }, so `onSuccess: closeModal` never
// runs. Asserts the request was DISPATCHED, not that the modal closes. A
// dropped success callback ships green.
sendMutate = jest.fn(); // never calls opts.onSuccess / opts.onError
it("sends the report to the provider", () => {
  result.current.onSendToProvider(42);
  expect(sendMutate).toHaveBeenCalledWith({ providerId: 42 }, expect.anything());
});

// GOOD: fire the success callback and assert the observable OUTCOME. Add a
// sibling test that fires opts.onError and asserts the snackbar.
it("closes the modal after a successful send", async () => {
  sendMutate.mockImplementation((_args, opts) => opts.onSuccess?.());
  result.current.onSendToProvider(42);
  await waitFor(() => expect(result.current.selectedReport).toBeUndefined());
});
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
