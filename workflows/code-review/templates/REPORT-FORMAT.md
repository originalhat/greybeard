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

## ⚠️ Nits

{N}. {The change, in one sentence.} ↳ {LENS-NAME} · `{file or class}`
{N}. {The change.} ↳ {LENS-NAME} · `{file or class}`

Cross-repo: {one line — clean, or the breakage folded in as a numbered failure above}

Ask for any number for file:line, the call path, and a full fix.
```

Print the `## ⚠️ Nits` heading only when there is at least one nit. If nothing failed and nothing was nitted, the tally line plus `Cross-repo:` and the closing offer is the entire report. Do not pad it.

## Worked example

```
**1. Error banners stay on screen after a successful submission**
The claim form shows a red banner when a submission fails. The form does
not clear the banner, so it stays on screen after the next attempt
succeeds. Members think the claim failed, so they submit it again. The
queue gets duplicates, and staff must reconcile them by hand.
**Fix:** Clear the error state at the start of each submission.
↳ REACT-STATE · `ClaimForm.tsx`

**2. Members with no SSN on file are never enrolled**
The nightly eligibility sync writes one row for each member. It skips any
member with a blank SSN, and it does not record that it skipped them.
Those members are not enrolled until they try to use their card at a
pharmacy and it fails.
**Fix:** Add the skipped members to the sync report.
↳ BULK-WRITE-SAFETY · `EligibilitySyncJob`

## ⚠️ Nits

3. Rename `data` to `claim_lines`; the name does not say what the array holds. ↳ CLARITY-SIMPLICITY · `ClaimForm.tsx`
4. Extract the repeated date format string into a constant. ↳ OPPORTUNISTIC-REFACTOR · `EligibilitySyncJob`
5. Wrap the icon-only Retry button in a label so a screen reader announces it. ↳ ACCESSIBILITY · `ClaimForm.tsx`
```

Each nit is one line: the change, then the footer. No context sentence, no consequence, no separate `Fix:` line — the line already is the fix.

## Language

Write every finding in **Simplified Technical English at about a 10th grade reading level**. The parts of that standard that matter here:

- **Sentence length.** Finding bodies are descriptive text: 25 words maximum. The `Fix:` line is procedural: 20 words maximum, and one instruction only. Split anything longer.
- **Active voice.** `The job skips the member`, not `the member is skipped`.
- **Simple tenses.** Simple present for how the code behaves. Simple future for what will happen to users. No progressive or perfect forms — `the job writes one row`, not `the job is writing` or `the job has written`.
- **Keep the articles.** `The job skips the member with a blank SSN`, not `Job skips member with blank SSN`. Telegraphic phrasing reads fast to the author and slowly to everyone else.
- **Noun clusters: three words maximum.** `claim submission error state handling` and `eligibility sync batch failure report` are unreadable. Break them up with prepositions: `the error state on the claim form`, `the failure report for the sync`.
- **One word, one part of speech.** A verb stays a verb. Banned as nouns: *a submit, a skip, a fetch, a read, a write, an ask, a spend.* Use the real noun (`each submission`) or rewrite around the verb (`it does not record that it skipped them`).
- **One word, one meaning.** Pick a term for a thing and reuse it in every finding. Do not alternate between `member`, `user`, and `patient` for the same person.
- **No idioms, metaphors, or insider shorthand.** This is the rule most often broken. Banned: *blast radius, retry storm, thundering herd, footgun, this will bite us, papers over, load-bearing, silently, happy path, code smell, goes through.* Say what actually happens instead.
- **Positive over negative.** Prefer the positive form where one exists, and never coin a negative adjective. `not enrolled`, not `un-enrolled`.
- **Keep the domain nouns.** `transaction`, `migration`, `callback`, `index`, `N+1` are precise and stay. Expand an unusual acronym on first use. The ban is on figurative language, not on technical vocabulary. Targeting grade 10 rather than the spec's usual grade 6–9 is exactly what makes room for these.
- **No vague quantities.** `Every row in the table`, not `a lot of records`. `Takes about 40 seconds`, not `slow`.
- **Short paragraphs.** Two to four sentences per finding body. Six is the absolute ceiling.

The test: a competent engineer who has never opened this repo reads the finding once and can explain the problem to someone else.

Before printing the report, reread each finding against the three rules that are easiest to break by habit: passive voice, a dropped article, and a verb used as a noun.

The full ASD-STE100 controlled dictionary — roughly 900 approved words, one meaning each — is deliberately **not** adopted. That vocabulary would make code review findings vaguer, not clearer. The rules above are the parts that survive contact with technical writing.

## Rules

**Tally, not roster.** Never enumerate the passing lenses. The count is the signal; the names are noise. A reader who wants to know whether a specific lens ran can ask.

**Number every failure.** Numbers are the reader's handle for follow-up ("explain 3"). Number continuously and never renumber within a session.

**Order by severity, not by lens.** Most severe first. Severity means how much damage the bug does and how hard it is to undo. Silent data corruption outranks a missing test, which outranks an unmemoized calculation.

**The heading is the impact, not the mechanism.** Write the sentence the reader would use to explain the bug to a teammate who does not know the codebase.

- ✅ `Error banners stay on screen after a successful submission`
- ✅ `Members with no SSN on file are never enrolled`
- ❌ `useEffect dependency array omits submitState`
- ❌ `REACT-STATE: stale state in ClaimForm`

**Context, then consequence.** One sentence to orient the reader — what this code does and when it runs — then what goes wrong for a person or for the data. The heading already carries the impact, so nothing is buried by opening on context. Do not skip the context sentence; a consequence with no setup is what makes a reader stop and reverse-engineer the finding.

**Every failure ends with a Fix line.** One sentence, imperative, naming the actual change. Procedural text, so 20 words maximum and one instruction only. It comes before the `↳` footer.

- ✅ `**Fix:** Clear the error state at the start of each submission.`
- ✅ `**Fix:** Move the rescue inside the transaction so a partial import rolls back.`
- ❌ `**Fix:** Consider refactoring for better state management.` — vague, and hedged
- ❌ `**Fix:** This violates the single responsibility principle.` — a principle, not a change
- ❌ A code block, a diff, or three bullets of alternatives

If the fix needs a decision you cannot make, say that in the same shape: `**Fix:** Needs a call — either fail the whole batch or report the skipped rows.` An honest fork beats a confident guess.

**One paragraph, hard cap.** No nested bullets, no code blocks, no before/after diffs, no line numbers in the body. All of that is follow-up material.

**Lens name and location go in the footer.** One `↳` line, dimmed to the side. The lens name is provenance, not a headline.

**Nits are one line each.** They are cheap to fix and easy to miss, so print them — but keep them small. One line per nit, under a single `## ⚠️ Nits` heading after the failures.

- **The line is the change.** Imperative, 15 words maximum, one instruction. A nit has no consequence worth a sentence; if it does, it is a failure, not a nit.
- **Numbered in the same run as the failures.** If there are 2 failures, the first nit is 3. The reader asks about any number, and depth comes out the same way.
- **The same `↳` footer,** on the same line as the nit rather than below it.
- **No grouping, no theme headings, no prose.** A flat list, ordered by file so a reader can fix them in one pass.
- **Twelve is the ceiling.** Past that, print the first twelve and add one line: `+{N} more nits — ask to see them.` A wall of nits buries the failures, which is the problem this format exists to prevent.

## Lenses that resist impact framing

Some lenses — extensibility, clarity, opportunistic refactor, testing coverage — have no direct user-facing consequence. Frame the impact on the **next engineer or the next incident** instead of forcing a fake user story:

- ✅ `No test covers the partial-failure path, so a regression here ships without warning`
- ✅ `A third claim type requires edits to five files that do not reference each other`
- ❌ `This violates separation of concerns`

If a finding has no consequence you can state in a sentence — for the user, the operator, the data, or the next engineer — it is a nit. Move it to the nit list and cut it down to one line.

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
- A nit written in the failure shape — a heading, a context sentence, and its own `Fix:` line
- Thirty nits printed in full, so the two real failures scroll off the top
- Findings the fact-check step could not confirm, hedged into the report anyway — drop them
- Metaphors doing the work a plain sentence should do
- Telegraphic phrasing with the articles stripped out, as if the report were a commit subject line
- Four nouns stacked into one phrase because it was faster to write than to unpack
