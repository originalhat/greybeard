# Step 3: Record

**Who:** the round's subagent (frontier model). Starts only after every scout has returned.
**Input:** the scouts' blocks, step 1's evidence, `state.json`, `map.md`, `patterns.md`
**Output:** an updated `state.json`, `map.md`, `patterns.md`, and one slice record in `slices/`

This step decides what the knowledge base believes. It writes only to `$GREYBEARD_DATA/output/improve/{repo}/`.

## 1. Fact-check

For every candidate, open the code at the ref and confirm that the quoted code is there and the consequence follows from it. A candidate that doesn't hold is dropped, not hedged. Record why in the slice record.

Then check the scout's **Changes behavior** answer yourself, using OPPORTUNISTIC-REFACTOR's Behavior-Change Trap. A mechanical change alters what a value is or how it reads. A behavioral one alters what runs. If you are unsure, the answer is `yes`.

## 2. Dedupe

A candidate's **fingerprint** is `{LENS}:{first path}:{symbol}`, where the symbol is the class, method, or component that holds the first location. Two candidates in this run with the same fingerprint, or describing the same change, merge into one with both scouts' evidence.

Against `state.json` candidates with the same fingerprint, or the same change under a different lens:

| Existing status | Do |
|-----------------|----|
| `open`, `stale` | Update it: new `ref`, merged evidence, `status: open`. No new id |
| `building`, `built`, `merged` | Drop the new one |
| `rejected` | Drop it, unless the new evidence answers the rejection `reason`. Then reopen it with a note quoting the reason and the new evidence, and name it in the report |
| `out` with `kind: refactor` | Add the evidence to it. No new id |

## 3. Label

- **`safe`**: changes no behavior, or only adds tests.
- **`flagged`**: changes something a user or caller can notice, **and** the payoff is structural. Examples: converging on the standard component, deleting a divergent copy of shared logic, making two sites behave the same where one is the clear standard. Write `userVisible` in one sentence of user terms ("status chips in the referral list match the rest of the app"). It is the line the human approves.
- **`out`**: needs a ticket, not improve. That covers a fix whose payoff is correcting a defect rather than structure, anything from the security report, and anything touching schema, migrations, auth or permissions, sessions, routes or a public API, dependencies, or CI. Record it so it isn't lost, but step 4 never builds it. Set `kind`: `defect` when users or callers hit wrong behavior today (the finish files it in Linear), `refactor` when it is structural work too big for a round (below; also filed), `restricted` when it is structural work that happens to touch a restricted area (recorded, never filed). Findings from the security report are `restricted` here; `security-testing` owns them.

**Bigger than a round.** When the change is over the gate's caps (8 files, 250 lines) and has no first step that fits, label it `out` with `kind: refactor`, and set `approach`:

- **`one-pr`** (the default), however many files it touches, when every step is mechanical and behavior-preserving: moving or extracting components, renames, converting call sites to a standard that already exists. Specs plus a before/after screenshot check can prove it, and moved-line highlighting makes it quick to review. The care_platform split of two component files (I-107: 26 components, 34 files) was this. It ran as a campaign and didn't need to: one PR, low risk.
- **`campaign`** only when the work needs checkpoints one PR can't give: it changes behavior or a contract at many sites, touches data or migrations along the way, is a language or framework migration, or is more non-mechanical change than one person can review in a sitting (roughly 50+ files that aren't pure moves).

Write the ticket-ready goal in `fix`, in one or two sentences. Improve never starts a campaign or a large refactor itself; the finish proposes a ticket that recommends the approach, files it only if the human approves, and the human decides when to pick it up.

## 4. Rate

- **Value.** `high`: removes a real risk (an untested branch on a frequently changed path, an N+1 on a list endpoint), removes duplication across 3 or more sites, or converges on a standard `map.md` or the design spec already names. `medium`: a clear readability or structure win in a file that changes often, per the slice's reason line. `low`: local and cosmetic.
- **Confidence.** `high` when the evidence is deterministic (`lint`, `review-record`, `design-audit`, `duplicate`, `test-gap`) and the fact-check confirmed it. `low` when it rests on `reading` alone or the fact-check needed judgment.

`low`-value candidates are not added to the backlog. They go in the slice record and, if they recur, in `patterns.md`. The backlog only holds things worth a branch.

## 5. Write the state

Per `templates/STATE.md`: new candidates get `I-{nextId}` (increment `nextId`), with `ref`, `slice` (this run's record path), `run` (the run directory), `createdAt`, and `status: open`. A reopened candidate gets this `run` too, so the finish files it if it is a defect. `out` candidates also start `open`; step 4 skips them by label. Append one `visits` entry per slice file, the anchor and the `with` files, with the ref:

```bash
f=$GREYBEARD_DATA/output/improve/{repo}/state.json
jq --arg ref {ref} --arg at {YYYY-MM-DD} '.visits += ($ARGS.positional | map({path: ., sha: $ref, at: $at}))' "$f" --args {path} {path} {path} > "$f.tmp" && mv "$f.tmp" "$f"
```

## 6. Update the map

Add each convention a scout cited in two or more places, under the closest heading, with its citations and today's date. If one already listed is contradicted in this slice, don't delete it. Add `contradicted at {path:line} ({date})`. Three contradictions mean it isn't a convention: remove it and say so in the slice record. Never record a convention from one place.

## 7. Patterns, and synthesis

For each observation: add this slice to the matching pattern in `patterns.md` (by meaning, not exact name), or create the pattern. A pattern counts **distinct slices**, not sites. Three sites in one slice are still one slice.

A pattern **reaches the threshold** at 3 distinct slices, or sooner when a design-audit finding or a review record already shows 3 or more sites. When a pattern reaches it with no candidate linked yet, write one cross-cutting candidate:

- The smallest **first step** that fits the gate, usually: pick or extract the standard, then convert one or two sites. Label it `safe` or `flagged` as in section 3, with value `high`, and link it with `pattern`.
- If the remaining sites wouldn't fit one round, also write an `out` candidate with `kind: refactor` and an `approach` (section 3) for the rest, to be ticketed.
- Link both from the pattern's `Candidate:` line.

This is how the view widens: no run reads more than a slice, but the knowledge base sees across all of them.

## 8. Slice record

Write `slices/{YYYY-MM-DD}-{anchor-slug}.md` per `templates/SLICE-RECORD.md`. It lists every candidate the scouts raised with its outcome (`I-n` new, `merged into I-n`, `dropped: {why}`, `low value`), plus the lens groups, the linters that ran or didn't, and the evidence sources found. It is the audit trail when someone later asks why the backlog says what it says.
