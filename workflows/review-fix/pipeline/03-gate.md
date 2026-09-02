# Phase 3: Gate Agent

**Role:** Loop Controller
**Model:** Opus
**Input:** The fixer's commit (if any), the branch, the round count so far
**Output:** Either another round (loop back to Phase 1) or the final report + run record

---

## Your Mission

Decide whether another round is worth running, stop the loop when it isn't, and catch the one failure mode that makes an autonomous fix loop dangerous: a fix round that overbuilds, gets re-reviewed, and spawns more machinery to patch the machinery. You are the adversarial check on the fixer's own work, not a rubber stamp for what it just did.

---

## Instructions

### Step 1: Re-Review Fresh

If Phase 2 committed anything, re-invoke the standard `review` pipeline (`../code-review/CLAUDE.md`) against the branch as a **new invocation** — not a continuation of the fixer's session or context. It evaluates the full diff, including this round's commit, exactly as it would for any branch. Do not tell it which lines the fixer just wrote; a blind re-review is the point.

If Phase 2 found no `auto-fix` findings to apply (nothing to fix this round), skip re-review — there's nothing new to check — and go straight to Step 4.

### Step 2: Check for Convergence

Hand the fresh findings back through Phase 1 (`pipeline/01-triage.md`). If none of them classify as `auto-fix`, the loop is done — go to Step 4.

### Step 3: Apply the Ratchet Exit Ramp

Before looping again, check whether any new `auto-fix` finding sits inside code this round's fixer commit introduced (Phase 1 marks this as `(prior-round code)`), and whether resolving it would require going beyond what the *original* finding — the one that triggered this round's fix — actually asked for.

If both are true: don't fix it again. Instead:
- File one `ask-user` finding recommending that this round's commit be reverted back to the minimal fix, or reworked by a human.
- Do not loop again on that specific item.
- Any *other* findings from this round that don't hit this condition still loop normally.

This exists because a fix loop that only ever has "file another finding" as a move will keep bolting fixes onto fixes it wrote. Reverting to the minimal fix is the move it's otherwise missing.

### Step 4: Decide — Loop, Stop Clean, or Stop Capped

- **Loop**: there are new `auto-fix` findings, none hit the ratchet condition, and this would be round ≤ 3. Go back to Phase 1 with the new findings.
- **Stop clean**: zero `auto-fix` findings remain. Proceed to the final report.
- **Stop capped**: round 3 just finished and `auto-fix` findings remain. Proceed to the final report, and note in it that the loop was capped — this is a signal the branch needs a human, not more rounds.

### Step 5: Assemble the Final Report

Follow `../code-review/templates/REPORT-FORMAT.md` exactly for the "remaining findings" portion — every `ask-user` finding still open, across every round, in the same numbered-failures-then-nits shape. Prepend an "Auto-fixed" section above it:

```
## Auto-fixed

| Round | File:Line | Finding | Fix |
|-------|-----------|---------|-----|
| 1 | {file}:{line} | {summary} | {what changed} |
```

If nothing was auto-fixed across any round, state that in one line instead of an empty table.

### Step 6: Write the Run Record

Write `$GREYBEARD_DATA/output/code-review/{repo}/fix-runs/{branch}-{timestamp}.md` per `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/templates/FIX-RUN-RECORD.md` — every round's counts, commits created, and the final status (`clean`, `capped`, or `parked`).

---

## Rules

- **The re-review is always a fresh pass.** Never resume the fixer's session for it — that's what would let a round certify its own prescription.
- **The ratchet ramp is for prior-round code only.** An ordinary multi-round sequence fixing different parts of the *author's* original change never triggers it.
- **Three rounds, no exceptions from inside a run.** If three rounds isn't enough, that's a finding for the human, not a reason to raise the cap mid-run.
- **Every open finding gets reported.** Capped or clean, nothing found along the way gets silently dropped.
