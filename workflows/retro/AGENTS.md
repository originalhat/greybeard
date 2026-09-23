# Retro Workflow

A retrospective over recent bb threads. It reads what the agent did, measures where the user had to correct, steer, retry, or wait, and proposes the most deterministic fix for each recurring pattern. The user approves; the workflow applies, records, and commits. High-confidence fixes are applied during the run and reported with a rollback; the user approves the rest. It is the feedback loop for every other workflow in this repo.

## Directory Structure

```
retro/
├── AGENTS.md              # You are here
├── lenses/                # One file per thing phase 2 looks for; add a file to extend
│   ├── AGENTS.md          # Lens shape and the table of general lenses
│   └── {NAME}.md          # CORRECTIONS, STEERS, TOOL-FAILURES, WAITING, …
├── pipeline/
│   ├── 01-gather.md       # Window, thread list, exclusions
│   ├── 02-summarize.md    # Per-thread summaries: header fields + one line per lens
│   ├── 03-synthesize.md   # Patterns → suggestions, ranked by the fix ladder
│   ├── 04-report.md       # Report, state, commit
│   └── 05-apply.md        # Auto-apply, walkthrough, apply, reject, rollback, changelog, commits
└── templates/
    ├── RETRO-REPORT.md    # Report shape
    ├── SUGGESTION.md      # One suggestion: 2x2 placement, magnitude, before/after impact, rollback
    ├── THREAD-SUMMARY.md  # What a summarizing subagent returns
    └── STATE.md           # state.json schema and status vocabulary
```

## Purpose

Agents repeat mistakes across threads because nothing reads across threads. This workflow does. It looks for the same correction given twice, the same manual step done three times, the same tool failure rediscovered every session, and turns each into one concrete change. It prefers changes that remove the cause over rules that ask the agent to remember.

## Inputs

- The bb CLI (`bb thread list`, `bb thread log`, `bb project list`). Threads across all projects unless `--project <name>` narrows it.
- `$RETRO_HOME`: where state, reports, designs, and the changelog live. Default `${GREYBEARD_DATA:-$HOME/.greybeard-data}/output/retro/`. Set it to a directory inside a **private** git repo to get history and revert for free. Never point it at a public repo: reports describe internal threads, tickets, and vendors.
- Optional `$RETRO_HOME/lenses/*.md`: private lenses, same shape as `lenses/*.md`, for one team's recurring pains or metrics. Read alongside the general lenses; a private lens with the same filename replaces the general one.
- Optional `$RETRO_HOME/links`: one line per tracked config file, `<live path><TAB><path relative to RETRO_HOME>`, for config files that are symlinked into the repo. Each run verifies and repairs them (see `04-report.md`).
- Optional MCPs: Linear or Jira for turning large suggestions into tickets, GitHub for reading PRs cited as evidence.

## Outputs

- `$RETRO_HOME/reports/YYYY-MM-DD.md` per run, per `templates/RETRO-REPORT.md`. Appends a `## Run N` section on a second run the same day.
- `$RETRO_HOME/state.json` per `templates/STATE.md`: last window end, reviewed thread ids, every suggestion ever made with its status and reason.
- `$RETRO_HOME/designs/S-*.md` for suggestions too large to apply directly.
- `$RETRO_HOME/CHANGELOG.md`: one line per applied suggestion, newest first, with the commit or file it changed and any deviation from the proposal.
- Commits in the `RETRO_HOME` repo (path-scoped) after each run and each applied suggestion, pushed if a remote exists. Commits in other repos only when applying a suggestion there, following that repo's convention, never pushed unless the user asks.

## Modes

- **`retro`** (default, typed or scheduled): phases 1–3, then auto-apply (phase 5) for the high-confidence quadrants, then the report (phase 4), then the walkthrough over what is left. The run ends by presenting the first remaining suggestion and waiting for approve / skip / change, so a scheduled run parks there until the user opens the thread. Everything auto-applied is listed in the report with its rollback.
- **`retro --report-only`**: phases 1–4 only, with no auto-apply. Ends on the report and the open list. For when the user wants to read first and decide later.
- **`retro walkthrough`**: phase 5 alone, over every `proposed` suggestion, in any thread. Use it to resume a parked run or to work through suggestions from several runs.
- **`retro apply <ids>` / `retro reject <ids> [reason]`**: phase 5 for the named ids, no presentation.
- **`retro rollback <ids> [reason]`**: undo applied suggestions with their recorded rollback step (`05-apply.md` § Rollback).
- **`retro status`**: read `state.json`, print open and handed-off suggestions with quadrant, effort, and ladder rung, plus accepted (auto and approved), rejected, deferred, and rolled-back counts. No changes.

## Execution

Phases are sequential. Read each pipeline file when you reach it.

1. **Gather** (`pipeline/01-gather.md`): title the thread with the run date, check handed-off suggestions, compute the window, list qualifying threads, exclude the workflow's own threads.
2. **Summarize** (`pipeline/02-summarize.md`): one structured summary per thread — fixed header fields plus one line per lens in `lenses/` and `$RETRO_HOME/lenses/` — via foreground subagents.
3. **Synthesize** (`pipeline/03-synthesize.md`): cluster summaries into patterns, quantify each, check what guidance already exists, choose the lowest rung on the fix ladder that removes the cause, place each on the value by confidence 2x2, write suggestions with their before and after.
3b. **Auto-apply** (`pipeline/05-apply.md` § Auto-apply): apply the high-confidence suggestions that are local, checkable, and reversible; verify, commit, record the rollback. Skipped with `--report-only`.
4. **Report** (`pipeline/04-report.md`): write the report and state, verify links, commit, list what was applied and what needs the user's hands.
5. **Walkthrough** (`pipeline/05-apply.md`): present the remaining suggestions one at a time; apply each only on the user's approval, exactly as approved; record; commit; present the next.

### Model tiers

- Summaries (phase 2): the `retro-summarizer` agent (`agents/retro-summarizer.md`), Sonnet at high effort with read-only tools, one subagent per thread, all launched in one message in the foreground.
- Synthesis, evidence verification, and apply (phases 3 and 5): the most capable model available. These need judgment.

## Principles

- **Quantify everything.** A theme without numbers is an anecdote. Every theme and every suggestion opens with a magnitude line: threads affected out of threads reviewed, the nonzero counts in words, and time lost last, always. See `templates/SUGGESTION.md` for the line and `03-synthesize.md` for what to count.
- **Impact before mechanism.** Every suggestion says what the user experiences today (Before), what changes (After), and how the next retro will know (`templates/SUGGESTION.md`).
- **Rank on a 2x2.** Value (time lost, reach, corrections, recurrence) by confidence (cause established, fix checkable now). The quadrant orders the report and the walkthrough; the fix ladder still chooses the fix.
- **Fix ladder.** Prefer the change that makes the mistake impossible over the one that asks the agent to remember. Prose in CLAUDE.md or AGENTS.md is the last rung, not the first. Details in `03-synthesize.md`.
- **Evidence is read, not inferred.** Before a suggestion goes in the report, the top evidence threads are checked against the actual log turns. A bb `steer` is guidance sent mid-turn, not a stall. A tool that fails inside the sandbox may work outside it. A count the user could challenge with "did this really happen seven times?" must survive that question.
- **High confidence ships, low confidence waits.** High-confidence suggestions that are local, checkable, and reversible in one step are applied during the run and reported with their rollback; the user reviews and rolls back. Everything else waits for approval. Nothing outward-facing is ever automatic. Rejected and rolled-back suggestions are never re-applied automatically. Deferred ones wait for new evidence.
- **PHI-free.** Summaries, reports, and state describe situations generically. No member names, identifiers, dates of birth, credentials, or test-data values, even from staging.
- **Finish the turn.** Subagents run in the foreground. The run ends once, on the report. No status lines between batches.

## Components

### Lenses (`lenses/`)

What the retrospective measures. Each lens is one countable kind of friction with its signal in the log, its unit, the exact summary line it produces, its typical rung on the fix ladder, and its false positives. Ten ship with the workflow (`lenses/AGENTS.md` lists them). Extending the retrospective means adding a lens file, in this repo for general ones or in `$RETRO_HOME/lenses/` for private ones; nothing else changes.

### Pipeline (`pipeline/`)

The five phases above, one file each.

### Templates (`templates/`)

`RETRO-REPORT.md` (report shape), `SUGGESTION.md` (one suggestion, used by the report and the walkthrough), `THREAD-SUMMARY.md` (what a summarizing subagent returns: header fields plus the lens lines), `STATE.md` (`state.json` schema and status vocabulary).

## Notes

- The workflow's own threads carry `[retro]` in their first message. Exclude them from the window; include everything else, including the thread that created the automation.
- `bb thread log --format minimal --limit N` silently drops the oldest turns of a long thread. Always use `--all`. For timings use `--format json --all`, which carries `createdAt` per event.
- Use absolute paths in Bash. `cd` inside a compound command can trip shell hooks in some environments.
- Editing the user's Claude settings, hooks, or skills directories may be refused by the auto-mode permission classifier as self-modification. When that happens, print the exact change for the user to paste and record the suggestion as `handed-off`; the next run's phase 1 verifies it and marks it `accepted`.
