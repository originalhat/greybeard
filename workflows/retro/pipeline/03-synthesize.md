# Phase 3: Synthesize

Turn the summaries into a small number of quantified, evidenced suggestions, each with the most deterministic fix available.

## 1. Cluster

Work lens by lens first: for each lens, line up its summary lines across all threads and look for the same cause. Then look across lenses, because one cause often shows up in several (a sandbox failure under `TOOL-FAILURES`, the retry under `MANUAL-STEPS`, the minutes under `WAITING`). A pattern is named by its cause, not by the lens that caught it.

Group summary items into patterns. A pattern needs the same underlying cause in **two or more threads**, or one thread where it cost more than fifteen minutes or three corrections. One-off mistakes go in the report's observations section, not in a suggestion.

Signals worth clustering on:

- the same correction from the user
- the same context the user had to supply again
- the same manual, multi-step task done by hand
- the same tool, permission, or sandbox failure and the same retry
- the same skill needing the same manual patch-up after it ran
- the same design overreach (built more than the ticket asked)
- system or MCP notices repeated across sessions (deprecations, auth failures)

## 2. Quantify

Every pattern carries a **magnitude line** before anything else is written about it, in the format of `templates/SUGGESTION.md`:

```
Magnitude: {affected}/{reviewed} threads · {nonzero counts, in words} · about {N} minutes lost
```

Example: `Magnitude: 1/15 threads · 7 failed commands · 1 streak of 3 failed fetches · about 14 minutes lost`.

Rules:

- Threads affected and reviewed are exact counts from phase 1 and 2.
- Counts are distinct events, not threads. Seven `gh` failures in one thread is seven failed commands in one thread. Name each count in words (corrections, repeated steers, failed commands, streaks, noise messages, manual steps); leave out the ones that are zero.
- Time lost always closes the line. It is a sum of the durations phase 2 attributed to this pattern, rounded to five minutes above ten. When the logs do not show it, write `time lost not measurable from the logs`. Do not estimate what the logs do not show.
- When a number is small, say so plainly. "1/24 threads" is a valid magnitude line and usually means the pattern belongs in observations.

## 3. Verify the evidence

For every pattern that will become a suggestion, open the top two evidence threads yourself (`bb thread log <id> --format minimal --all`, read only the region around the cited event) and confirm:

- the event happened as described, in the agent's turn or the user's, as claimed
- a claimed stall is a real turn boundary, not a steer
- a claimed tool breakage was not a sandbox artifact (if the log shows it working after a sandbox-off retry, it is sandbox friction)
- the user's words are quoted, short, and exact

Drop or downgrade what does not survive. Write one line per verified item in the suggestion's evidence list, quoting the user where a correction is the evidence.

## 4. Check what already exists

Before proposing, read the guidance that already applies, so the suggestion is not a duplicate and so you know which rung is already occupied:

- the user's global Claude instructions and settings, and the bb `AGENTS.md`
- `CLAUDE.md`, `AGENTS.md`, `.claude/`, `CLAUDE.local.md` in every `environmentPath` from phase 1
- the skills and workflows in this repo and in the user's skills directories
- Claude's memory directory for the projects involved
- `state.json`: never re-propose a `rejected` id. For a `proposed` or `deferred` id with fresh evidence, add the evidence under that id instead of creating a new one.

## 5. Choose the rung on the fix ladder

For each pattern, walk the ladder top to bottom and stop at the first rung that removes the cause. Say which rung you chose and why the rungs above it do not apply. The lens that caught the pattern names its **typical fix rung**; start there, but the cause decides, not the lens.

Before any rung, check whether an existing instruction causes the behavior: a skill step, a default, or a line in a doc the agent read. Removing or narrowing it beats adding a rule on any rung (S-20260923-3: `/implement` went to the review clone because step 1 told it to). And when the agent read the right instruction and did not follow it, another copy of that instruction is not a fix (S-20260923-4); go to a lower-numbered rung or record an observation.

1. **Configuration or tooling.** Sandbox allow-lists and excluded commands, MCP endpoints and auth, permission rules, environment variables, git or editor config. Deterministic: the failure cannot recur. Example: excluding `gh` from the sandbox instead of a rule about retrying unsandboxed.
2. **Structure.** Worktrees instead of a shared checkout, a script that does the manual steps, an automation, a template, a hook. The agent does not have to remember because the environment does it.
3. **Skill mechanics.** A new step, flag, record, or check inside an existing workflow or skill. Still deterministic when the skill runs: a `--skip-ui` flag, a run record written at step 11, a nit prefix applied by the loop.
4. **Memory.** A fact the agent needs and cannot derive: where something lives, what a term means, what the user decided.
5. **Prose rule** in `CLAUDE.md`, `AGENTS.md`, or `CLAUDE.local.md`. Last resort, for behavior that is genuinely judgment and cannot be mechanized. When you land here, write the rule as a default with its scope, not a prohibition: say where the risk is ("production", "shared checkouts") rather than "never". Users soften absolutes on sight, and an absolute that is wrong once gets ignored twice.

Structural fixes (rung 2) are often `large`. For those, propose a spike and offer to open a ticket (Linear or Jira MCP when available) plus a design note under `$RETRO_HOME/designs/`, rather than an edit.

## 6. Place it on the 2x2 and write it

Every suggestion gets a **value** and a **confidence**, each `high` or `low`. Together they are its quadrant, and the quadrant orders the report and the walkthrough: high value · high confidence, then high value · low confidence, then low value · high confidence, then low value · low confidence. The ladder rung still says *how* to fix; the quadrant says *how much it matters and how sure we are*.

**Value is high** when any of these holds; otherwise it is low:

- about 15 minutes or more lost in the window
- three or more threads affected
- at least one user correction, or the same steer in two or more threads
- the pattern recurs across runs: it is fresh evidence against an earlier suggestion whose fix did not hold

**Confidence is high** when both hold; otherwise it is low:

- the cause is established: seen in three or more threads, or two threads plus a correction quoted verbatim, or reproduced or read directly in this run (the failing command re-run, the defect read in source or config)
- the fix can be checked when it is applied, by a command, a test, or a parse, not only by waiting for future threads

Write each suggestion in the shape of `templates/SUGGESTION.md`: `id` (`S-YYYYMMDD-n`), title, value, confidence, `ladder` (1–5), `category` (`config`, `structure`, `skill-fix`, `memory`, `claude-md`, `other`), `target`, `effort` (`small` under 30 minutes, `medium` under half a day, `large` beyond), the magnitude line, **Before**, **After**, **How we'll know**, the verified evidence list, the change concrete enough to apply as written, and the rollback. Before and after are the impact the user reads first; write them in terms of what the user experiences, and keep After within what the evidence supports.

Mark overlaps explicitly: `supersedes`, `superseded-by`, `complements`. The report presents overlapping suggestions together so the user decides once.

Quality bar: three suggestions with real numbers beat ten guesses. A run with none is a valid result. Everything else worth noting goes in observations with its own magnitude line.
