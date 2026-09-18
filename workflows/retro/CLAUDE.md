# Retro Workflow

A retrospective over recent bb threads. It reads what the agent did, measures where the user had to correct, steer, retry, or wait, and proposes the most deterministic fix for each recurring pattern. The user approves; the workflow applies, records, and commits. It is the feedback loop for every other workflow in this repo.

## Directory Structure

```
retro/
├── CLAUDE.md              # You are here
├── pipeline/
│   ├── 01-gather.md       # Window, thread list, exclusions
│   ├── 02-summarize.md    # Per-thread summaries with counts and timings
│   ├── 03-synthesize.md   # Patterns → suggestions, ranked by the fix ladder
│   ├── 04-report.md       # Report, state, commit
│   └── 05-apply.md        # Walkthrough, apply, reject, changelog, commits
└── templates/
    ├── RETRO-REPORT.md    # Report shape
    ├── THREAD-SUMMARY.md  # What a summarizing subagent returns
    └── STATE.md           # state.json schema and status vocabulary
```

## Purpose

Agents repeat mistakes across threads because nothing reads across threads. This workflow does. It looks for the same correction given twice, the same manual step done three times, the same tool failure rediscovered every session, and turns each into one concrete change. It prefers changes that remove the cause over rules that ask the agent to remember.

## Inputs

- The bb CLI (`bb thread list`, `bb thread log`, `bb project list`). Threads across all projects unless `--project <name>` narrows it.
- `$RETRO_HOME`: where state, reports, designs, and the changelog live. Default `${GREYBEARD_DATA:-$HOME/.greybeard-data}/output/retro/`. Set it to a directory inside a **private** git repo to get history and revert for free. Never point it at a public repo: reports describe internal threads, tickets, and vendors.
- Optional `$RETRO_HOME/links`: one line per tracked config file, `<live path><TAB><path relative to RETRO_HOME>`, for config files that are symlinked into the repo. Each run verifies and repairs them (see `04-report.md`).
- Optional MCPs: Linear or Jira for turning large suggestions into tickets, GitHub for reading PRs cited as evidence.

## Outputs

- `$RETRO_HOME/reports/YYYY-MM-DD.md` per run, per `templates/RETRO-REPORT.md`. Appends a `## Run N` section on a second run the same day.
- `$RETRO_HOME/state.json` per `templates/STATE.md`: last window end, reviewed thread ids, every suggestion ever made with its status and reason.
- `$RETRO_HOME/designs/S-*.md` for suggestions too large to apply directly.
- `$RETRO_HOME/CHANGELOG.md`: one line per applied suggestion, newest first, with the commit or file it changed and any deviation from the proposal.
- Commits in the `RETRO_HOME` repo (path-scoped) after each run and each applied suggestion, pushed if a remote exists. Commits in other repos only when applying a suggestion there, following that repo's convention, never pushed unless the user asks.

## Modes

- **`retro`** (default, typed or scheduled): phases 1–4, then straight into phase 5's walkthrough. The run ends by presenting the first open suggestion and waiting for approve / skip / change. A scheduled run therefore parks on suggestion 1 until the user opens the thread; that is intended. Nothing is applied until the user answers.
- **`retro --report-only`**: phases 1–4 only. Ends on the report and the open list. For when the user wants to read first and decide later.
- **`retro walkthrough`**: phase 5 alone, over every `proposed` suggestion, in any thread. Use it to resume a parked run or to work through suggestions from several runs.
- **`retro apply <ids>` / `retro reject <ids> [reason]`**: phase 5 for the named ids, no presentation.
- **`retro status`**: read `state.json`, print open suggestions with effort, confidence, and ladder rung, plus accepted/rejected/deferred counts. No changes.

## Execution

Phases are sequential. Read each pipeline file when you reach it.

1. **Gather** (`pipeline/01-gather.md`): compute the window, list qualifying threads, exclude the workflow's own threads.
2. **Summarize** (`pipeline/02-summarize.md`): one structured summary per thread, with counts and durations, via foreground subagents.
3. **Synthesize** (`pipeline/03-synthesize.md`): cluster summaries into patterns, quantify each, check what guidance already exists, choose the lowest rung on the fix ladder that removes the cause, write suggestions.
4. **Report** (`pipeline/04-report.md`): write the report and state, verify links, commit, end the turn with the summary and the one-line walkthrough offer.
5. **Apply** (`pipeline/05-apply.md`): present one suggestion at a time; apply each only on the user's approval, exactly as approved; record; commit; present the next.

### Model tiers

- Summaries (phase 2): a fast mid-tier model, one subagent per batch of threads, run in the foreground.
- Synthesis, evidence verification, and apply (phases 3 and 5): the most capable model available. These need judgment.

## Principles

- **Quantify everything.** A theme without numbers is an anecdote. Every theme and every suggestion states: threads affected out of threads reviewed, occurrences, user corrections or steers it cost, retries or failed commands, and minutes lost where the log timestamps allow. See `03-synthesize.md` for what to count and how.
- **Fix ladder.** Prefer the change that makes the mistake impossible over the one that asks the agent to remember. Prose in CLAUDE.md or AGENTS.md is the last rung, not the first. Details in `03-synthesize.md`.
- **Evidence is read, not inferred.** Before a suggestion goes in the report, the top evidence threads are checked against the actual log turns. A bb `steer` is guidance sent mid-turn, not a stall. A tool that fails inside the sandbox may work outside it. A count the user could challenge with "did this really happen seven times?" must survive that question.
- **Propose, then wait.** The scheduled run never applies anything. Rejected suggestions are never re-proposed. Deferred ones wait for new evidence.
- **PHI-free.** Summaries, reports, and state describe situations generically. No member names, identifiers, dates of birth, credentials, or test-data values, even from staging.
- **Finish the turn.** Subagents run in the foreground. The run ends once, on the report. No status lines between batches.

## Notes

- The workflow's own threads carry `[retro]` in their first message. Exclude them from the window; include everything else, including the thread that created the automation.
- `bb thread log --format minimal --limit N` silently drops the oldest turns of a long thread. Always use `--all`. For timings use `--format json --all`, which carries `createdAt` per event.
- Use absolute paths in Bash. `cd` inside a compound command can trip shell hooks in some environments.
- Editing the user's Claude settings file may be refused by the auto-mode permission classifier as self-modification. When that happens, print the exact change for the user to paste and record the suggestion as `accepted` with that note once they confirm.
