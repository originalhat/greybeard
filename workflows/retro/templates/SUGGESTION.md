# Suggestion

One suggestion has two layers. The **card** is what the user reads in the final message and the walkthrough: a one-line header and a short paragraph, nothing else. The **details** (magnitude, before/after, evidence, change, rollback) live in the report file and are shown in the thread only when the user asks for them.

## Card

```markdown
## {Issue in plain English} · quadrant {1–4}/4 · {about N min lost | time lost not measurable} · {applied | handed off | needs input | deferred} · {id}
{Two to four sentences. Problem: what kept happening, counts in words ("three threads, nine denials"). Impact: what it cost the user. Fix: what changes, in one sentence, naming a file or rung only when the user has to go there.}
```

Rules for the card:

- The header is plain English, not the target path. "Network git still fights the sandbox" beats "compound-git-approve.sh v4".
- Quadrant numbers follow the order below; `1/4` is high value · high confidence.
- Time lost is the magnitude line's closing figure and nothing else.
- Status is one word or two: `applied` (auto or approved), `handed off` (the user has commands to run), `needs input` (walkthrough), `deferred`.
- No Evidence, Change, Rollback, or Before-you-decide in the card. A `handed off` card is followed by its command block, because the user has to run it; that is the only code allowed under a card.
- Never more than four sentences. Leave things out rather than pack them in.

## Details

The report prints the card header, the card paragraph, and then these fields. The walkthrough prints them only when the user says `details`.

```markdown
{card header}
{card paragraph}

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
