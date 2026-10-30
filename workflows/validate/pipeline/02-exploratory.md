# Explore

The exploring half of testing: designing and running small experiments in quick succession, with each result steering the next. This file holds the charter step, the session and debrief loop, and confirmation. Skipped with `--check-only`.

**This is the tuning surface.** Change the round cap, the session budget, and the stop conditions here as real runs show over- or under-exploring.

## Charter (frontier model)

A charter is a mission for one session:

> Explore **{target}** with **{resources}** to discover **{information}**.

- **Target:** one surface, entity, state, or data path from the change map.
- **Resources:** what the session brings: a lens, a persona, a data set, a role, a tool (throttling, a second tab, the console), or another feature to combine with the target.
- **Information:** the risk being looked for, in user terms.

A good charter points without prescribing. "Explore the note form with pasted spreadsheet text to discover ways a coordinator's note is saved differently than typed" is a charter. "Paste 'a\tb' into the note field and click Save" is a test case. "Explore the app for bugs" is too broad to finish.

Draw charters from these sources, in roughly this order:

1. **The check's failures and leads.** A failed criterion gets a charter that explores around it. One bug usually means more nearby.
2. **The Never and Always list.** One charter per rule a user would be hurt by: "Explore … to discover any way a member can see another member's claim."
3. **The nightmare headline.** Imagine the worst plausible headline about this change, like "Clinic double-billed for every visit after Tuesday's update". List what could cause it, and turn each cause into a charter.
4. **The intent's claims and implicit expectations.** Each claim in the PR or ticket ("works the same as create") is worth testing. So are the expectations nobody writes down: the existing roles still apply, and it is not slower than before.
5. **The lenses.** For each lens in `../lenses/`, run it only if the change shows one of its signals and the surface uses one of its interfaces.
6. **History.** `git log --oneline -20 -- {touched files}`. Past fix commits mark areas that broke before.

Rank by risk to the user. Aim for 4 to 8 charters. This list is the **backlog**.

## Session (Sonnet, one at a time)

One fresh subagent per session, given `../PERSONA.md`, the change map, the top 1 to 3 charters, every lens file those charters name, the findings and leads so far, and the interfaces, URLs, and logins. An agent that already thinks an area is clean is the wrong agent to send back into it. Sessions share one app and one database, so they never run in parallel.

Budget: about 40 actions (browser actions, requests, or console calls).

The session returns:

- **Findings:** something a user or caller would call wrong. Each one has numbered repro steps from a clean start, expected vs. observed, a screenshot or captured response, and the oracle it broke (see `../PERSONA.md`).
- **Questions:** behavior that is not clearly wrong but that someone could stumble on.
- **Leads:** odd things noticed and not yet followed, like a flicker, an off-by-one count, a console or log error, a slow response, or an unexplained extra write.
- **New charters:** ideas the session had that would have taken it off its charter. It writes them down instead of chasing them.
- **Coverage:** what it tried, one line per charter, including what worked as expected.

## Debrief (frontier model)

Update the backlog the way a test lead would:

- **Follow the bugs.** Add a charter that digs into a finding's area with a different lens, persona, or variable.
- **Turn leads and new charters into backlog items** when they touch the change map. Drop the rest, and say so in the record.
- **Retire** charters the session covered. Never rerun a charter with the same resources. A second pass needs a different lens, persona, or data set.
- **Reorder** by risk to the user.

Print one line per round: `Round {n}: {charters run} · {N} findings · {N} leads · {N} charters left`.

## Stop

Stop when any of these is true:

- The backlog is empty, with no open questions about the change.
- A round produced no new findings and no new leads. Exploration has stopped teaching anything.
- The round cap is reached (default 4). Remaining charters go under the report's **Not covered**, and they are the reason to raise the cap next time.
- A finding makes the rest of the backlog meaningless (for example, the main screen crashes). Report it right away.

## Confirm (Sonnet, fresh)

A fresh subagent replays each finding's repro steps from a clean start.

- If it reproduces, the finding is `confirmed`.
- If it doesn't, assume a variable is not under control yet. Every bug reproduces once all its variables are controlled. From the session notes, list what might have mattered: timing, the previous state, the number of times an action had run, the role, the data, leftover records. Vary those for up to three more tries. If it still won't reproduce, mark it `couldn't reproduce` and report it in its own section, with what was seen and the variables tried. Don't drop it, and don't count it as a bug.

Then decide scope for each confirmed finding from the diff, without switching branches. If the repro path runs through code or a screen the branch changed, it is `introduced`. If it plainly does not, it is `pre-existing`. Otherwise it is `unconfirmed`. With `--stack`, an `introduced` finding also names the lowest layer whose own diff touches its repro path: `introduced in <branch>`.
