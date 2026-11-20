# Testing Coverage Reviewer

Identify gaps in test coverage, test quality issues, and tests that don't actually verify behavior.

Unlike a pattern-scan lens, this is a **join**: you cannot judge coverage by sweeping the diff once. Work the method below in order — enumerate first, *then* judge — or you will silently skip changed units you never got around to. That omission is the failure mode this lens exists to prevent (see `onSuccess: closeModal` in the callback section).

## Method

Do these four passes **in order**. Do not start judging tests until enumeration is complete.

1. **Enumerate** — list every changed hunk that introduces or changes **runtime behavior**. Include new/changed functions, branches, callbacks, and handlers. Exclude pure refactors, renames, type-only changes, comments, and formatting. This list is your checklist; every item gets a verdict.
2. **Locate** — for each enumerated unit, find the test that covers it (search test files by symbol/behavior, not just "was a test file touched"). If none exists, the verdict is a coverage gap.
3. **Judge** — for each located test, apply the criteria in *What to Flag*: does the path actually execute (not an empty collection / unfired callback), and does it assert the **observable outcome** (not just dispatch)?
4. **Scan the tests themselves** — separately from the join, read every test the diff adds or changes for the problems under *Timing Issues* and *Exact-Time Assertions*. A test can cover its unit and still fail on a clean branch; this pass needs no changed production code to trigger it.

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
- a **polymorphic association, STI base, or type column** where every fixture builds the same concrete type (`owner: member` when `owner_type` allows ten); require one example per type the code treats differently, plus one for a type it should ignore

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

### Exact-Time Assertions Against the Real Clock
The flake that does not look like one: the code under test computes a time from the clock (`perform_in(1.minute)`, `5.minutes.from_now`, `Time.current + interval`), and the test computes the expected time from the clock **again, a moment later** (`have_enqueued_sidekiq_job(id).in(1.minute)`, `.at(1.minute.from_now)`, `eq(5.minutes.from_now)`). The two reads differ by however long the test ran in between. Matchers that compare whole seconds pass until that gap crosses a second boundary, so the test fails about once per N CI runs and passes every time it is read or rerun.

Flag any assertion that compares an exact time or interval when the clock is not frozen across both reads (`Timecop.freeze`, `travel_to`, `freeze_time`, `jest.useFakeTimers().setSystemTime`). `Timecop.travel` does not count: the clock keeps running. Severity is **HIGH**, never a nit: the failure blocks CI on unrelated PRs and teaches people to rerun red builds. A sibling spec in the same file that also skips the freeze does not excuse it. That is the same defect twice, and the finding names both.

A jest test whose measured run time is near its timeout is the same class of defect. It is only visible when CI timings are in the PR context, but when they are, a test above half its timeout is a HIGH finding.

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

```ruby
# BAD: the job reads the clock at perform, the matcher reads it again at the
# expect. Fails whenever a second ticks over in between (care_platform
# referrals_spec and the fax job specs: 7 assertions that failed main's CI on
# and off for two weeks before they were frozen).
it "checks again later while the fax is still going out" do
  described_class.new.perform(fax.id)
  expect(described_class).to have_enqueued_sidekiq_job(fax.id).in(ReferralFax::CHECK_EVERY)
end

# GOOD: one frozen clock for both reads.
it "checks again later while the fax is still going out" do
  Timecop.freeze do
    described_class.new.perform(fax.id)
    expect(described_class).to have_enqueued_sidekiq_job(fax.id).in(ReferralFax::CHECK_EVERY)
  end
end
```

## Severity

- **CRITICAL**: Core functionality untested, tests pass with broken code
- **HIGH**: Important paths untested, flaky tests, exact-time assertions against an unfrozen clock
- **MEDIUM**: Edge cases untested, could use better assertions

## False Positives to Avoid

- Trivial getters/setters tested through usage
- Private methods tested via public interface
- Code covered by integration tests
- Refactoring without behavior change (no new tests needed)
