# Review Report Format

The canonical output format for the code-review workflow. Both `workflows/code-review/CLAUDE.md` and the `/review` skill point here — edit this file, not the copies.

The reader is the engineer who wrote the code. They want to know **what breaks, who feels it, and what to do**, in that order. They do not want to reverse-engineer impact from a call chain. Depth is available on request; it is never the opening move.

## Shape

```
Review · {repo} {#pr or branch} · {N} lenses

✅ {N} passed   ❌ {N} failed   ⚠️ {N} nits

## ❌ Failures

**1. {Impact — what goes wrong, in plain language}**
{One sentence of context: what this code does, and when it runs.}
{Then the consequence: what a user, an operator, or the data experiences.}
**Fix:** {One sentence. Imperative. Names the change, not the principle.}
↳ {LENS-NAME} · `{file or class}`

**2. {Impact}**
{Context sentence. Consequence sentence.}
**Fix:** {One sentence.}
↳ {LENS-NAME} · `{file or class}`

Cross-repo: {one line — clean, or the breakage folded in as a numbered failure above}

Ask for any number for file:line, the call path, and a full fix.
```

If nothing failed, the tally line plus `Cross-repo:` and the closing offer is the entire report. Do not pad it.

## Worked example

```
**1. Error banners stay on screen after a claim submits successfully**
The claim form shows a red banner when a submission fails. The banner is
never cleared, so it is still there after the next attempt succeeds.
Members think the claim did not go through. They submit it again, and the
queue gets duplicates that staff must reconcile by hand.
**Fix:** Clear the error state at the start of each submit.
↳ REACT-STATE · `ClaimForm.tsx`

**2. Members with no SSN on file never get enrolled**
The nightly eligibility sync writes one row per member. It skips any
member with a blank SSN and does not record the skip. Those members stay
un-enrolled until they try to use their card at a pharmacy and it fails.
**Fix:** Write the skipped members to the sync report so someone can act on them.
↳ BULK-WRITE-SAFETY · `EligibilitySyncJob`
```

## Language

Write every finding in **Simplified Technical English at about a 10th grade reading level**. The parts of that standard that matter here:

- **Short sentences.** Around 20 words, hard stop at 25. Split anything longer.
- **Active voice.** `The job skips the member`, not `the member is skipped`.
- **Simple tenses.** Simple present for how the code behaves. Simple future for what will happen to users.
- **One word, one meaning.** Pick a term for a thing and reuse it in every finding. Do not alternate between `member`, `user`, and `patient` for the same person.
- **No idioms, metaphors, or insider shorthand.** This is the rule most often broken. Banned: *blast radius, retry storm, thundering herd, footgun, this will bite us, papers over, load-bearing, silently, happy path, code smell.* Say what actually happens instead.
- **Keep the domain nouns.** `transaction`, `migration`, `callback`, `index`, `N+1` are precise and stay. Expand an unusual acronym on first use. The ban is on figurative language, not on technical vocabulary.
- **No vague quantities.** `Every row in the table`, not `a lot of records`. `Takes about 40 seconds`, not `slow`.
- **Short paragraphs.** Two to four sentences per finding body. Six is the absolute ceiling.

The test: a competent engineer who has never opened this repo reads the finding once and can explain the problem to someone else.

## Rules

**Tally, not roster.** Never enumerate the passing lenses. The count is the signal; the names are noise. A reader who wants to know whether a specific lens ran can ask.

**Number every failure.** Numbers are the reader's handle for follow-up ("explain 3"). Number continuously and never renumber within a session.

**Order by severity, not by lens.** Most severe first. Severity means how much damage the bug does and how hard it is to undo. Silent data corruption outranks a missing test, which outranks an unmemoized calculation.

**The heading is the impact, not the mechanism.** Write the sentence the reader would use to explain the bug to a teammate who does not know the codebase.

- ✅ `Error banners stay on screen after a claim submits successfully`
- ✅ `Members with no SSN on file never get enrolled`
- ❌ `useEffect dependency array omits submitState`
- ❌ `REACT-STATE: stale state in ClaimForm`

**Context, then consequence.** One sentence to orient the reader — what this code does and when it runs — then what goes wrong for a person or for the data. The heading already carries the impact, so nothing is buried by opening on context. Do not skip the context sentence; a consequence with no setup is what makes a reader stop and reverse-engineer the finding.

**Every failure ends with a Fix line.** One sentence, imperative, naming the actual change. It comes before the `↳` footer.

- ✅ `**Fix:** Clear the error state at the start of each submit.`
- ✅ `**Fix:** Move the rescue inside the transaction so a partial import rolls back.`
- ❌ `**Fix:** Consider refactoring for better state management.` — vague, and hedged
- ❌ `**Fix:** This violates the single responsibility principle.` — a principle, not a change
- ❌ A code block, a diff, or three bullets of alternatives

If the fix needs a decision you cannot make, say that in the same shape: `**Fix:** Needs a call — either fail the whole batch or report the skipped rows.` An honest fork beats a confident guess.

**One paragraph, hard cap.** No nested bullets, no code blocks, no before/after diffs, no line numbers in the body. All of that is follow-up material.

**Lens name and location go in the footer.** One `↳` line, dimmed to the side. The lens name is provenance, not a headline.

**Nits are a count.** They appear in the tally and nowhere else. Do not list them, tally them by theme, or mention them again in prose.

## Lenses that resist impact framing

Some lenses — extensibility, clarity, opportunistic refactor, testing coverage — have no direct user-facing consequence. Frame the impact on the **next engineer or the next incident** instead of forcing a fake user story:

- ✅ `No test covers the partial-failure path, so a regression here ships without warning`
- ✅ `Adding a third claim type means editing five files that do not reference each other`
- ❌ `This violates separation of concerns`

If a finding has no consequence you can state in a sentence — for the user, the operator, the data, or the next engineer — it is a nit. Move it to the count.

## Holding depth for follow-up

Detail is kept **in working context, not written to disk**. When aggregating and fact-checking, retain per-finding `file:line`, the call path, and the full fix even though none of it is printed. Follow-ups ("what's the fix for 2?") must be answerable without re-running the diff or re-reading the lens.

The one-sentence Fix line is a direction, not a patch. The patch is follow-up material.

## Anti-patterns

These are the specific noise sources this format exists to kill:

- A PASS/FAIL line for all 33 lenses
- Per-lens sections, each with its own heading, when most found nothing
- Restating the diff back to the reader as a summary of changes
- `file:line` in the opening report
- Code blocks showing the current code, the fixed code, or both
- Severity labels *and* emoji *and* a lens name on the same line
- A closing "Recommendations" section that repeats the Fix lines as imperatives
- Findings the fact-check step could not confirm, hedged into the report anyway — drop them
- Metaphors doing the work a plain sentence should do
