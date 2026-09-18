# Phase 1: Gather

Decide the window, collect the threads, exclude the noise.

## Window

Read `$RETRO_HOME/state.json` (create it from `templates/STATE.md` if missing).

- Start: `lastRunAt`. If null, 24 hours ago.
- `--days N` or `--since YYYY-MM-DD` overrides the start. Cap at 14 days: beyond that the summaries stop being comparable and the run gets slow.
- End: now. Record both as epoch ms; the report prints them as dates in the user's timezone.

## Threads

```bash
bb thread list --json
bb thread list --archived --json
bb project list --include-personal --json
```

Keep a thread when `updatedAt` is inside the window. Exclude:

- the current thread (`$BB_THREAD_ID`)
- any thread whose `title` or `titleFallback` contains `[retro]`
- threads already in `reviewedThreadIds` **unless** their `updatedAt` is after `lastRunAt` (they had new activity; re-read them, and in the summary say what is new)
- `--project <name>` when given: keep only that project's threads

Map `projectId` to project names. Keep `environmentPath`, `providerId`, `status`, `createdAt`, `updatedAt` per thread; the summaries and the report use them.

## Zero threads

Write a two-line report (window, "no qualifying threads"), set `lastRunAt` to the window end, commit if `RETRO_HOME` is in a repo, and end the turn. Do not invent suggestions from nothing.

## Hand-off

Produce the list `[{id, title, project, environmentPath, provider, status, createdAt, updatedAt, previouslyReviewed}]` and pass it to phase 2 in batches of five to eight threads.
