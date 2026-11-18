# Step 4: Build

**Who:** the round's subagent, running `${CLAUDE_PLUGIN_ROOT}/workflows/implement/AGENTS.md` for one candidate on the batch branch
**Input:** the brief (branch, checkout path, round base SHA, steer), `state.json`, or an explicit `I-n`
**Output:** this round's commits on the batch branch, a review run record, a gate result, the candidate's updated status, and the round report

The branch and the checkout (or worktree) already exist; the parent made them. This step never creates a branch, switches branches, pushes, or opens a PR.

## 1. Select

With an explicit `I-n`, take it if its label is `safe` or `flagged` and its status is `open` or `stale`. Otherwise report why not and build nothing. An `out` candidate is never built here; it becomes a ticket at the finish.

Otherwise, from candidates with `status: open`:

1. Keep `safe` with value `high` or `medium`, and `flagged` with value `high`. A behavior change has to be worth it.
2. Order by value, then `safe` before `flagged`, then confidence `high` before `low`, then **lower id** (the oldest first). Size is not a tiebreaker: on the first CP run, smallest-first let each new slice's tiny test gap jump the queue for three rounds while the bigger, older items waited.
3. Apply the brief's steer. Usually that is the variety rule: after two `test-only` rounds, prefer the best qualifying candidate that changes app code.
4. Skip candidates whose files the batch branch already changed in an earlier round when another qualifies. Two rounds editing one file is allowed, but it makes the commits harder to review on their own.
5. Take the first one that still holds (section 2).

If none qualify, report `nothing to build`, name the closest candidate and what it lacks, and stop. That is a normal outcome.

## 2. Still holds?

Read the candidate's locations at the branch's HEAD, not only at `origin/main`, since an earlier round may have changed them. `git log --format=%h {candidate.ref}..HEAD -- {candidate paths}` empty means nothing changed. If the problem is gone, set `status: stale` and go back to section 1. If it moved, update the locations and `ref`.

Set the candidate's `status: building`, `branch`, and `run`.

## 3. Before screenshots (flagged UI changes only)

When the candidate is `flagged` and its locations include a view, template, component, or stylesheet, load each page the change affects at the round base, the way implement's render check does, and take one screenshot per page, named `{id}-before-{page}.png` in thread storage. Implement's render check takes the after shots.

## 4. Run implement

Run `${CLAUDE_PLUGIN_ROOT}/workflows/implement/AGENTS.md` on the batch branch. Its step 1 sees a feature branch and continues on it. The input is freeform requirements built from the candidate:

```
{title}

Problem: {consequence} at {locations}.
Evidence: {evidence}.
Change: {fix}

Acceptance:
- safe → Behavior is unchanged. The existing tests that cover {paths} pass without edits.
         If the changed path has no test, write a characterization test first, against the current code, and keep it.
- flagged → {userVisible}. Nothing else a user can see changes.

Scope: only what the change above needs. Anything else noticed goes in the round report, not the branch.
```

- **Flags:** always `--no-validate`; the finish validates the combined branch once. `--skip-ui` unless the candidate is `flagged` and touches UI, where the render check takes the after shots. Never `--pr`. With a worktree, work in it and don't create another.
- **Review only this round.** Implement's review and its `review --fix` cover `{round base}..HEAD`, not the whole branch: run the review as `review --since {round base}`, and give `review-fix` the same SHA. Earlier rounds were reviewed in their own rounds.
- **TDD for a `safe` change:** implement's red step becomes the characterization test. It must pass before the change and after it. Prove it can fail: break the code it covers, see it fail, restore. A test that only passes after the change means the change wasn't behavior-preserving; relabel the candidate `flagged` (or `out`) and report it instead of shipping it as `safe`.
- **Test-only candidates** (`test-gap`, a spec that passes whether or not the code works): the test is the change. Still prove each new or tightened example fails when the behavior it pins is broken.
- **Implement's closing list becomes the round report.** Its decisions, questions, and **Not fixed** items go in the report for the parent; nothing waits for the human mid-run. For a `flagged` candidate, the first decision is `{userVisible}. Flagged behavior change, built because {payoff}. Before/after: {screenshot paths}`.

## 5. Scope gate

From the checkout:

```bash
IMPROVE_BASE={round base} ${CLAUDE_PLUGIN_ROOT}/workflows/improve/scripts/scope-gate.sh
```

- **`pass`:** the round is done.
- **`fail`:** park the round. `git branch improve-parked/{id} HEAD`, then `git reset --hard {round base}`, so the next round starts clean. When the caps failed, relabel the candidate `out` with `kind: refactor` and an `approach` (03-record section 3), so the finish tickets it; when it only hit a denylist path, leave it `open` with the reason. Report `parked`. When every reason is a denylist false positive the candidate really needed (care_platform's `referral_authorization*`), keep the commits instead and say so in the report; the parent lists it under **Needs you**.

A round that can't finish for another reason (a test it can't make pass, a review failure it can't fix) parks the same way.

## 6. Record and report

Set `status: built` with `branch`, `commits` (the round's SHAs), and `run`. Then return the round report from `templates/ROUND-BRIEF.md`. The **Behavior to validate** line matters most for the finish: for an `app-code` round, name the flows a user goes through that touch the changed code ("schedule, cancel, and send-now failure messages on the care request composer") and whether the change is `unchanged` or `flagged`. For a `test-only` round, write `none`.
