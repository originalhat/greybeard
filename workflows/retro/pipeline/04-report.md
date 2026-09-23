# Phase 4: Report

Write the report and the state, keep the repo honest, end the turn once.

## Report

Write `$RETRO_HOME/reports/YYYY-MM-DD.md` per `templates/RETRO-REPORT.md`, dated in the user's timezone. If the file exists, append a `## Run N` section instead of overwriting.

Write it in a few small commands, not one compound command that also updates state and commits: a single very large heredoc can be refused by the permission classifier as a transient error and you lose the whole step. Report file first, then state, then the commit.

## State

Update `$RETRO_HOME/state.json` per `templates/STATE.md`:

- `lastRunAt` = window end
- append new suggestions with `status: "proposed"`, `proposedAt`, `reportDate`
- add reviewed thread ids to `reviewedThreadIds` (a set)
- for existing `proposed` or `deferred` ids that gained evidence, append to their `evidenceThreadIds` and bump `lastEvidenceAt`

## Links check

If `$RETRO_HOME/links` exists, for each `live path<TAB>repo-relative path` line confirm the live path is a symlink resolving into `RETRO_HOME`'s repo. Tools rewrite settings files as regular files sometimes, which silently breaks the link. When one is broken: copy the live file over the repo copy, restore the symlink, and say so in the report under observations.

## Commit

If `RETRO_HOME` is inside a git repo:

```bash
ROOT=$(git -C "$RETRO_HOME" rev-parse --show-toplevel)
git -C "$ROOT" add "$RETRO_HOME"
git -C "$ROOT" commit -m "retro: YYYY-MM-DD run, N threads, M suggestions" -- "$RETRO_HOME"
git -C "$ROOT" remote get-url origin >/dev/null 2>&1 && git -C "$ROOT" push
```

Path-scoped, so nothing else in that tree is swept in. If push fails, leave the commit local and say so.

## Final message

The user reads this and nothing else. In order:

1. A markdown link to the report file.
2. Two or three sentences: threads reviewed by project, and the themes, **each with its magnitude line**.
3. The 2x2 grid (value by confidence, ids in each cell), then the suggestion table in quadrant order: id, one-line description, quadrant, ladder rung, effort, magnitude line ending in time lost.
4. Overlaps, in one line each.
5. Then, unless `--report-only`, continue directly into `05-apply.md` and present suggestion 1 of N in the same message. The turn ends on its `Approve, skip, or tell me what to change.` line.

With `--report-only`, end instead with: `Say "retro walkthrough" to go through these one at a time.`

Nothing is applied in this phase.
