# Exploratory Testing Loop

Runs only when `validate` is invoked with `--exploratory`. Picks up where the acceptance check leaves off: instead of checking what was specified, it probes for what wasn't.

**This file is the tuning surface for exploratory mode.** Expect to revise the round cap, the exploration categories, and the stop condition as real runs show this over- or under-exploring. Don't fold those adjustments back into `../AGENTS.md` — keep them here so the rest of the pipeline stays stable while this part iterates.

## Why This Exists Separately From Acceptance Check

Acceptance check answers "does it do what the ticket says." Exploratory testing answers "what does it do that nobody said anything about" — the adjacent flow that shares a component with the change, the input nobody thought to specify, the state left behind after the happy path. Bugs found here are usually cheaper to fix now than after a user finds them.

## Loop Structure

Bounded at **3 rounds** by default. One subagent per round, model `sonnet`, fresh context each round (not a continuation of the previous round's session) — a round that already believes an area is clean is a bad agent to send back into it.

### Round Input

Each round's agent receives:
- The change's diff or description (what actually changed, so exploration stays near the change instead of wandering the whole app).
- The acceptance criteria and their pass/fail results from step 4, so the agent doesn't waste a round re-finding what's already known.
- Prior rounds' findings (round 2+), so rounds build on each other instead of repeating ground.

### Round Procedure

Each round picks 2-4 of the following categories to probe, biased toward whichever are most plausible for this specific change (a form change → boundary inputs and validation; a navigation change → adjacent flows and back/forward state; anything touching persistence → reload and multi-tab state):

- **Adjacent flows** — other features that share a component, a data model, or a code path with the change. Does the change's side effect show up somewhere unexpected?
- **Boundary and malformed inputs** — empty, very long, special characters, wrong type, duplicate submission (double-click, browser back-then-resubmit).
- **State after navigation** — reload, browser back/forward, opening in a second tab, deep-linking directly to a URL the change introduced.
- **Error and interruption paths** — what the UI shows if a network call the change depends on fails or is slow; what happens if the user abandons the flow partway and comes back.
- **Permissions and roles**, if the app has them — does the change respect the same access rules as the rest of the surface it's on.

For each thing probed: state what was tried, what was expected in the absence of any specific expectation (i.e., "shouldn't crash, shouldn't lose data, shouldn't show something contradictory"), and what was actually observed. Only things that diverge from that baseline are findings — exploratory testing is not obligated to report "tried X, was fine."

### Stop Condition

Stop before the 3-round cap if either:
- A round produces zero new findings (nothing this round wasn't already known from a prior round or the acceptance check) — the search has saturated for the areas being probed.
- A round surfaces a severe finding (data loss, security-relevant, crash) — stop and surface it immediately rather than continuing to explore around it.

Otherwise run all 3 rounds and stop.

### Synthesis

After the loop stops, one Opus pass over all rounds' raw findings:
- Dedupe (the same underlying bug found two different ways is one finding, not two).
- Rank by severity: **severe** (data loss, security, crash), **moderate** (wrong behavior, no data loss), **minor** (confusing but not incorrect — a UX nit).
- For each surviving finding, note whether it looks pre-existing (unrelated to this change, would reproduce on `main` too) or introduced by this change. Don't guess — check against `main` if it's a quick check, otherwise say "unconfirmed, worth checking against main."

## Output

A list, one entry per finding surviving synthesis:

```
- **{severity}** {one-sentence description of the bug/issue}
  Repro: {numbered steps}
  Scope: introduced by this change | pre-existing | unconfirmed
```

Feeds into `templates/VALIDATION-REPORT.md`'s Exploratory Findings section. If synthesis produces zero findings, the section states that plainly (what was probed, nothing found) rather than being omitted — a clean exploratory pass is itself useful information.
