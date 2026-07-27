# Opportunistic Refactor Reviewer

Spot small, tactical refactors worth doing *while we're already in this area* — the boy-scout-rule wins. This lens is about high-value, low-effort cleanups that ride along with the current change, **not** a mandate for a large refactor.

## The Core Test

Only flag something if **all** of these hold:

1. **Proximity** — the code is inside, or directly adjacent to, what this diff already touches. If reviewing it means opening files the PR never went near, it's out of scope.
2. **Low blast radius** — the change is self-contained and mechanical enough to verify by reading it. No cascading edits, no API changes rippling across callers.
3. **High value-to-effort** — a few minutes of work that measurably improves clarity, safety, or consistency.
4. **Rides along** — it makes sense to do *now, because we're here*. If it could just as easily be its own future ticket, prefer to note it, not block on it.

If a fix fails any of these, it belongs in a separate follow-up, not this lens. Say so rather than flagging it.

## The Behavior-Change Trap (does it change what *runs*, or just what a value *is*?)

The low-blast-radius test (#2) is about **whether you can verify the change by reading it** — and that hinges on a distinction that trivial-looking diffs hide:

- **Mechanical** — changes what a value *is* or how it *reads*: extract a variable, rename a local, dedupe a literal. The set of code that executes is unchanged. Safe to ride along.
- **Behavioral** — changes what *executes*: activating a no-op (assigning back a discarded `.preload`/`.map`/return value), making a dormant branch live, un-commenting, swapping a discarded result for a used one. **This has the blast radius of new code, not of a cleanup**, because code that never ran now runs — and any latent bug it contained fires for the first time. The diff looks like "assign a variable that was being thrown away"; the danger is the *content that assignment newly executes*.

A behavioral change fails test #2 unless the touched path **already has a test that exercises it** (or you add a characterization test in the same PR). "It reads fine" and "the suite is green" prove nothing about lines no test runs — full-suite green ≠ changed path covered. If the change is behavioral **and** the path is untested, do **not** flag it as a ride-along cleanup: call it out as a separate PR that needs its own test and review. (See `TESTING-COVERAGE`.)

This is not hypothetical: a discarded `.preload(...)` reassigned "to fix an N+1" activated an invalid clause that had been dormant behind the no-op, 500ing a core endpoint in prod.

## What to Flag

### Boy-Scout Wins (touch it, improve it)
- A function you're already editing that has one obvious extract-variable or extract-method opportunity
- Duplicated literal/logic where the *second* copy is being added in this diff — consolidate now, before the pattern spreads
- A stale comment or dead branch sitting right next to the changed lines
- A poorly-named local/param in the block being modified

### Cheap Consistency Fixes
- New code that reinvents a helper/util that already exists in the file or module
- Deviation from a nearby established pattern (e.g. the sibling function uses a guard clause; this one nests)
- Missing use of an existing constant/enum where a magic value was just introduced

### Adjacent Safety Nits
- An obvious nil/undefined guard missing on a value the diff now depends on
- A newly-touched call that ignores an error the surrounding code handles
- Broadening a `rescue`/`catch` that the diff sits inside, when a narrow one is trivial

### Seams Worth Widening (only if trivial)
- Pulling one inline value into a named constant that the change would benefit from
- Splitting one overloaded line the diff just made worse

## Patterns

```ruby
# Diff adds the second copy of this rounding logic.
# GOOD opportunistic fix: extract now, since we're introducing the dup.
amount = (cents / 100.0).round(2)   # existing
# ...new code in same method...
refund = (refund_cents / 100.0).round(2)   # <- flag: extract `to_dollars(cents)`
```

```javascript
// We're already editing this function. A named variable makes the
// new condition readable at zero risk.
if (user.plan === 'pro' && !user.trialExpired && seats < user.seatLimit) { // BAD
// GOOD
const canAddSeat = user.plan === 'pro' && !user.trialExpired && seats < user.seatLimit
if (canAddSeat) {
```

## Severity

Findings here are **suggestions, never blockers**. Frame them as opportunities.

- **HIGH**: Cheap fix that also removes a real latent bug or dup being introduced right now
- **MEDIUM**: Clear readability/consistency win in the touched code
- **LOW**: Nice-to-have; fine to defer to a follow-up

## Relationship to Other Lenses

This lens is deliberately narrow and scoped by *proximity*. The deep-dive versions live elsewhere — defer to them for anything beyond arm's reach of the diff:
- Structural/complexity problems → `CLARITY-SIMPLICITY-REVIEWER`
- Misplaced logic / layering → `SEPARATION-OF-CONCERNS-REVIEWER`
- Designing for future change → `EXTENSIBILITY-REVIEWER`

If a finding really belongs to one of those lenses and requires work beyond the local area, note it as a follow-up instead of flagging it here.

## False Positives to Avoid

- **Scope creep** — anything that expands the diff's footprint into untouched files. This is the #1 thing to resist.
- Rewrites, re-architecting, or "while you're at it, migrate…" suggestions
- Refactors that would need their own test pass or careful regression review
- Churn for taste alone with no clarity/safety/consistency payoff
- Re-flagging what a more specific lens already owns
- Pattern changes that fight the surrounding codebase's established style
- Suggesting a behavioral "cleanup" (see The Behavior-Change Trap) on an untested path as if it were a safe ride-along — it isn't; route it to its own PR with a test instead
