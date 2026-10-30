# Validation Report Format

The canonical output for the `validate` workflow. Printed at the end of the run and written to `$GREYBEARD_DATA/output/validate/{repo}/{YYYY-MM-DD}-{pr{n} | branch}/report.md`.

The reader is the author of the change, and possibly a PM. They want three things, in order: **does it do what it says**, **what will users trip on**, and **how hard did we look**. Repro steps are the evidence. Causes are not this workflow's job. Report evidence, not a ship verdict.

## Shape

```
Validate · {repo} {#pr or branch} · {ticket-id | "PR description" | "freeform"} · {interfaces used}

✅ {N} passed   ❌ {N} failed   ⚠️ {N} couldn't verify   🐞 {N} bugs   🤔 {N} questions   · {N} pre-existing

## Check

1. {criterion}: ✅ pass
2. {criterion}: ❌ fail
   Expected: {what should have happened}
   Observed: {what actually happened}
   Steps: {the steps that produced it}
3. {criterion}: ⚠️ couldn't verify
   Reason: {why}

## 🐞 Bugs

**4. {Impact: what the user experiences, in plain language}**
{What the user was doing. What happened instead, and what that costs them.}
Repro:
1. {step from a clean start}
2. {step}
↳ {severity} · {LENS} · {oracle} · {introduced | introduced in <branch> | unconfirmed} · `{screens/NN.png}`

## 🤔 Questions

{N}. {A question for the author, about what a user would experience.} ↳ {LENS}

## Couldn't reproduce

{N}. {What was seen once, and the variables tried since.} ↳ {LENS}

## Pre-existing

{N}. {The bug, in one sentence, with its real severity.} ↳ {LENS}

## Coverage

Explored: {charters run, one short phrase each, with rough depth}
Worked as expected: {notable things that held up under exploration}
Not covered: {charters left in the backlog, lenses skipped and why}

## Context

{Proposed lines for context/APPS.md, if the run had to ask for something or found a quirk.}
```

`## Check` and `## Coverage` always print. Every other heading prints only when it has content. With `--check-only`, the tally drops the 🐞 and 🤔 counts and the report ends after `## Check`. Do not pad a clean report.

## Rules

- Number everything in one sequence (criteria, bugs, questions, and the rest) so a reply can say "#4".
- Bugs rank by what the user loses: data, money, or access first, then wrong results, then confusion.
- With `--stack`, the header names the top branch and every ticket, the criteria are grouped by ticket, and `## 🐞 Bugs` has one `### {branch}` subheading per branch that introduced a bug, bottom layer first.
- A bug heading states impact, not mechanism. "Coordinators lose their typed note when the save fails", not "onSubmit error handler resets state".
- Repro steps start from a clean start (a fresh page load or a fresh request) and name the role and the data they need.
- Questions use the user's voice: concise, about user impact, and ending in a question mark. One sentence by default.
- No em dashes. No metaphors. Short active sentences.
- Hold console output, network details, and screenshots in context for follow-ups. Don't print them.

## Worked example

```
Validate · care_platform #1012 · ER-1477 · browser

✅ 3 passed   ❌ 0 failed   ⚠️ 0 couldn't verify   🐞 2 bugs   🤔 1 question   · 1 pre-existing

## Check

1. A coordinator can add a follow-up note to a visit: ✅ pass
2. The note shows on the visit timeline after a reload: ✅ pass
3. The member summary shows the latest note: ✅ pass

## 🐞 Bugs

**4. A double-click on Save creates the note twice**
The coordinator clicks Save twice while the request is in flight. Two
identical notes appear on the timeline, and the member's summary counts
both.
Repro:
1. Log in as the coordinator seed user and open any visit.
2. Type a note and double-click Save.
3. Reload the timeline.
↳ moderate · TIMING-AND-REPETITION · Never and Always · introduced · `screens/03.png`

**5. A note with an apostrophe shows as &#39; on the member summary**
The note looks right on the timeline. The summary card shows the raw
HTML entity, so "member's" reads as "member&#39;s".
Repro:
1. Add a note containing "member's plan".
2. Open the member summary.
↳ minor · FOLLOW-THE-DATA · Consistency within the app · introduced · `screens/05.png`

## 🤔 Questions

6. Should a coordinator get a warning before leaving the page with an unsaved note, since the note is lost without one? ↳ NAVIGATION-AND-HISTORY

## Pre-existing

7. The visit list logs a console error on every load, on main as well. Minor. ↳ ECOSYSTEM

## Coverage

Explored: inputs on the note field, double submit and slow save, reload and back mid-edit, every place a note shows up, the read-only role.
Worked as expected: the read-only role can't add or edit notes from the UI or the endpoint.
Not covered: keyboard and small screens (round cap reached).
```
