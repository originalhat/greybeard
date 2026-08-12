# Review Report Format

The canonical output format for the code-review workflow. Both `workflows/code-review/CLAUDE.md` and the `/review` skill point here — edit this file, not the copies.

The reader is the engineer who wrote the code. They want to know **what breaks and who feels it**, in that order. They do not want to reverse-engineer impact from a call chain. Depth is available on request; it is never the opening move.

## Shape

```
Review · {repo} {#pr or branch} · {N} lenses

✅ {N} passed   ❌ {N} failed   ⚠️ {N} nits

## ❌ Failures

**1. {Impact statement — what goes wrong, in plain language}**
{One short paragraph: the consequence first, then only as much mechanism
as is needed to make the consequence credible. 2–4 sentences.}
↳ {LENS-NAME} · `{file or class}`

**2. {Impact statement}**
{Paragraph.}
↳ {LENS-NAME} · `{file or class}`

Cross-repo: {one line — clean, or the breakage folded in as a numbered failure above}

Ask for any number for file:line, the call path, and a suggested fix.
```

If nothing failed, the tally line plus `Cross-repo:` and the closing offer is the entire report. Do not pad it.

## Rules

**Tally, not roster.** Never enumerate the passing lenses. The count is the signal; the names are noise. A reader who wants to know whether a specific lens ran can ask.

**Number every failure.** Numbers are the reader's handle for follow-up ("explain 3"). Number continuously and never renumber within a session.

**Order by severity, not by lens.** Most severe first. Severity means blast radius and reversibility — silent data corruption outranks a missing test, which outranks an unmemoized calculation.

**The heading is the impact, not the mechanism.** Write the sentence the reader would use to explain the bug to a teammate who doesn't know the codebase.

- ✅ `Error banners never clear after a successful retry`
- ✅ `Members missing an SSN silently never enroll`
- ❌ `useEffect dependency array omits submitState`
- ❌ `REACT-STATE: stale state in ClaimForm`

**Lead with the consequence.** Body paragraphs open on what happens to a user, an operator, or the data — then the mechanism, briefly. Not the reverse.

**One paragraph, hard cap.** No nested bullets, no code blocks, no before/after diffs, no line numbers in the body. All of that is follow-up material.

**Lens name and location go in the footer.** One `↳` line, dimmed to the side. The lens name is provenance, not a headline.

**Nits are a count.** They appear in the tally and nowhere else. Do not list them, tally them by theme, or mention them again in prose.

## Lenses that resist impact framing

Some lenses — extensibility, clarity, opportunistic refactor, testing coverage — have no direct user-facing consequence. Frame the impact on the **next engineer or the next incident** instead of forcing a fake user story:

- ✅ `No test covers the partial-failure path, so a regression here ships silently`
- ✅ `Adding a third claim type means editing five files that don't reference each other`
- ❌ `This violates separation of concerns`

If a finding has no consequence you can state in a sentence — for the user, the operator, the data, or the next engineer — it is a nit. Move it to the count.

## Holding depth for follow-up

Detail is kept **in working context, not written to disk**. When aggregating and fact-checking, retain per-finding `file:line`, the call path, and the suggested fix even though none of it is printed. Follow-ups ("what's the fix for 2?") must be answerable without re-running the diff or re-reading the lens.

## Anti-patterns

These are the specific noise sources this format exists to kill:

- A PASS/FAIL line for all 33 lenses
- Per-lens sections, each with its own heading, when most found nothing
- Restating the diff back to the reader as a summary of changes
- `file:line` in the opening report
- Code blocks showing the current code, the fixed code, or both
- Severity labels *and* emoji *and* a lens name on the same line
- A closing "Recommendations" section that repeats the failures as imperatives
- Findings the fact-check step couldn't confirm, hedged into the report anyway — drop them
