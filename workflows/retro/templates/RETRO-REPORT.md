# Retro Report

Written to `$RETRO_HOME/reports/YYYY-MM-DD.md`. A second run the same day appends `## Run 2` with the same sections.

```markdown
# Retro · {YYYY-MM-DD}

Window: {start date time} → {end date time} ({timezone})
Threads reviewed: {N} ({project}: {n}, {project}: {n}, …) · {n} previously reviewed with new activity
Outcomes: {done} done · {handed off} handed off · {stalled} stalled · {abandoned} abandoned · {in progress} in progress
Totals: {corrections} corrections · {steers} steers · {failed} failed commands · about {minutes} minutes the user waited on the agent

## Themes

### {Theme title, plain language}
Magnitude: {affected}/{N} threads · {nonzero counts, in words} · about {N} minutes lost
{Two to four sentences. What kept happening, what it cost, quoting the user once where a correction is the evidence.}
→ {suggestion ids}, or "observation only"

## Applied automatically

| id | what changed for you | commit or backup | rollback |
|----|----------------------|------------------|----------|
| {id} | {before → after, one sentence} | {repo sha | backup path} | `{command}` |

## Needs your hands
- **{id}**: {why it could not be applied}. Run: `{command}`

## Suggestions

|                | High confidence | Low confidence |
|----------------|-----------------|----------------|
| **High value** | {ids}           | {ids}          |
| **Low value**  | {ids}           | {ids}          |

### High value · high confidence
{each suggestion in the shape of templates/SUGGESTION.md, headed `(applied)`, `(handed off)`, or `(walkthrough: {rule})`}

### High value · low confidence
{…}

### Low value · high confidence
{…}

### Low value · low confidence
{…}

## Observations (no suggestion yet)
- {pattern}. Magnitude: {…}. {Why it did not become a suggestion: single thread, unclear fix, waiting for recurrence.}

## Housekeeping
- Links check: {all intact | repaired: path}
- Deferred suggestions with fresh evidence: {ids} | none
- {Anything the run itself hit: a log that would not load, a project it could not map}

## Threads reviewed
| id | title | project | outcome | corrections | steers | failed cmds | min waited |
|----|-------|---------|---------|-------------|--------|-------------|------------|
```

Rules: every theme and suggestion opens with its magnitude line, which always ends with time lost; an empty quadrant is omitted from the headings but kept in the grid as `none`; `n/a` where the logs do not support a number; no member identifiers, credentials, or test-data values; the report is for the user, the thread summaries are not reproduced in it.
