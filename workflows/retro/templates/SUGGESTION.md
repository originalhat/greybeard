# Suggestion

The shape of one suggestion. The report prints every suggestion this way, and the walkthrough presents each one this way, so the user reads the same fields in the same order every time.

```markdown
### {id}: {title in plain language}
{value} value · {confidence} confidence · rung {1–5} ({config | structure | skill mechanics | memory | prose}) · {effort} · {target}

**Magnitude:** {affected}/{reviewed} threads · {nonzero counts, in words} · about {N} minutes lost

**Before:** {What happens today, from the user's side. One to three sentences, anchored on the worst instance and what it cost.}
**After:** {What the user sees once this lands: which failures, steps, or messages go away, and what stays the same. Say how the magnitude numbers should move.}
**How we'll know:** {A check that runs now (a command, a test, a parse) and the signal the next retro should count.}

**Evidence:**
- {thread id} "{thread title}": {one line; the user's words quoted when a correction is the evidence}

**Change:**
{Exact text in a code block for prose and config; steps and file placement for skills, scripts, and structure.}

**Rollback:** {one command or step that undoes it}
**Before you decide:** {overlaps with other ids, uncommitted work in the target, a convention this changes} | none
```

## Magnitude line

Lead with threads affected out of threads reviewed. List only the counts that are not zero, in words ("7 failed commands", "1 streak of 3 failed fetches", "2 corrections"). Always end with time lost: `about N minutes lost`, rounded to five minutes above ten, or `time lost not measurable from the logs`. Example:

```
Magnitude: 1/15 threads · 7 failed commands · 1 streak of 3 failed fetches · about 14 minutes lost
```

## Before and after

- Written for the user, not about plumbing. "Every PR review retries its first fetch outside the sandbox" beats "excludedCommands does not match compound commands".
- **Before** is what the logs show, with its cost. No speculation about threads that were not reviewed.
- **After** claims no more than the evidence supports. When a change reduces a count rather than removing it, say "fewer" and which instances it would have prevented.
- **How we'll know** must be something the next retro can count from its own summaries: "0 `==== not found` exits", "no waiting lines in implement's review step". A check that only a human can judge does not qualify.

## Quadrant

`value` and `confidence` are each `high` or `low`, set in `pipeline/03-synthesize.md` step 6. Together they place the suggestion in one of four quadrants, which order the report and the walkthrough:

1. high value · high confidence
2. high value · low confidence
3. low value · high confidence
4. low value · low confidence
