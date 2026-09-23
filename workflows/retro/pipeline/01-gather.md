# Phase 1: Gather

Decide the window, collect the threads, exclude the noise.

## Thread title

For a `retro` run (typed or scheduled), first set this thread's title to the run date so runs are told apart in the sidebar:

```bash
bb thread update --self --title "Retro · YYYY-MM-DD"
```

Use the date in the user's timezone. A second run the same day is `Retro · YYYY-MM-DD (run 2)`. `retro walkthrough`, `apply`, `reject`, and `status` in another thread leave that thread's title alone.

## Window

Read `$RETRO_HOME/state.json` (create it from `templates/STATE.md` if missing).

- Start: `lastRunAt`. If null, 24 hours ago.
- `--days N` or `--since YYYY-MM-DD` overrides the start. Cap at 14 days: beyond that the summaries stop being comparable and the run gets slow.
- End: now. Record both as epoch ms; the report prints them as dates in the user's timezone.

## Handed-off suggestions

For each suggestion in `state.json` with `status: handed-off`, run its `impact.verify` check. When it passes, set `status: accepted` with `reason` noting the date it was found in place. When it does not, keep it `handed-off`; the report lists it under Housekeeping and the final message repeats the commands the user still needs to run.

## Threads

```bash
bb thread list --json
bb thread list --archived --json
bb project list --include-personal --json
```

Keep a thread when `updatedAt` is inside the window. Exclude:

- the current thread (`$BB_THREAD_ID`)
- any thread whose `title` or `titleFallback` contains `[retro]` (or the legacy marker `[claude-improvement-review]` from the automation this workflow replaced). Scheduled threads get a generated title without the marker, so also check the first user message: `bb thread log <id> --format minimal --all | head -3`
- threads already in `reviewedThreadIds` **unless** they have log events after `lastRunAt`. `updatedAt` alone is not enough: archiving, pinning, or reading a thread bumps it without new activity. Confirm with the json log (`bb thread log <id> --format json --all`, last `createdAt` > `lastRunAt`) before re-reading, and in the summary say what is new
- `--project <name>` when given: keep only that project's threads

Map `projectId` to project names. Keep `environmentPath`, `providerId`, `status`, `createdAt`, `updatedAt` per thread; the summaries and the report use them.

## Zero threads

Write a two-line report (window, "no qualifying threads"), set `lastRunAt` to the window end, commit if `RETRO_HOME` is in a repo, and end the turn. Do not invent suggestions from nothing.

## Hand-off

Produce the list `[{id, title, project, environmentPath, provider, status, createdAt, updatedAt, previouslyReviewed}]` and pass it to phase 2 in batches of five to eight threads.
