# Retro Report

Written to `$RETRO_HOME/reports/YYYY-MM-DD.md`. A second run the same day appends `## Run 2` with the same sections.

```markdown
# Retro · {YYYY-MM-DD}

Window: {start date time} → {end date time} ({timezone})
Threads reviewed: {N} ({project}: {n}, {project}: {n}, …) · {n} previously reviewed with new activity
Outcomes: {done} done · {handed off} handed off · {stalled} stalled · {abandoned} abandoned · {in progress} in progress
Totals: {corrections} corrections · {steers} steers · {failed} failed commands · ~{minutes} min the user waited on the agent

## Themes

### {Theme title, plain language}
Magnitude: {a}/{N} threads · {occurrences} occurrences · {corrections} corrections, {steers} steers · {retries} failed commands · ~{minutes} min lost
{Two to four sentences. What kept happening, what it cost, quoting the user once where a correction is the evidence.}
→ {suggestion ids}, or "observation only"

## Suggestions

### {id}: {title}
- **Category / ladder / target:** {category} · rung {1–5} ({config | structure | skill mechanics | memory | prose}) · {file, repo, setting, or skill}
- **Magnitude:** {magnitude line}
- **Evidence:**
  - {thread id} "{title}": {what happened, one line; the user's words quoted if a correction}
  - …
- **Why this rung:** {one line on why the rungs above do not remove the cause}
- **Proposed change:** {exact text in a code block for prose and config; steps and placement for skills, scripts, and structure}
- **Effort / confidence:** {small | medium | large} · {low | medium | high}
- **Overlaps:** supersedes {id} | complements {id} | none

## Observations (no suggestion yet)
- {pattern} — Magnitude: {…}. {Why it did not become a suggestion: single thread, unclear fix, waiting for recurrence.}

## Housekeeping
- Links check: {all intact | repaired: path}
- Deferred suggestions with fresh evidence: {ids} | none
- {Anything the run itself hit: a log that would not load, a project it could not map}

## Threads reviewed
| id | title | project | outcome | corrections | steers | failed cmds | min waited |
|----|-------|---------|---------|-------------|--------|-------------|------------|
```

Rules: every theme and suggestion opens with its magnitude line; `n/a` where the logs do not support a number; no member identifiers, credentials, or test-data values; the report is for the user, the thread summaries are not reproduced in it.
