# Phase 4: Report

Write the report and the state, keep the repo honest, end the turn once.

## Report

Write `$RETRO_HOME/reports/YYYY-MM-DD.md` per `templates/RETRO-REPORT.md`, dated in the user's timezone. If the file exists, append a `## Run N` section instead of overwriting.

Write it in a few small commands, not one compound command that also updates state and commits: a single very large heredoc can be refused by the permission classifier as a transient error and you lose the whole step. Report file first, then state, then the commit.

## State

Update `$RETRO_HOME/state.json` per `templates/STATE.md`:

- `lastRunAt` = window end
- append new suggestions with `proposedAt`, `reportDate`, and the status auto-apply left them in (`accepted` with `autoApplied: true`, `handed-off`, or `proposed`)
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

The user reads this and nothing else. It is short and scannable: cards, not tables or field lists. In order:

1. A markdown link to the report file, then one sentence: threads reviewed by project and how they ended.
2. One **card** per suggestion (`templates/SUGGESTION.md` § Card), in quadrant order, applied ones included; the status word in the header tells them apart. A `handed off` card is followed by its command block. No 2x2 grid, no suggestion table, no Evidence, Change, or Rollback; those are in the report. Overlaps are one clause inside the card paragraph ("replaces yesterday's S-…"), not a separate list.
3. **Watching:** at most five observations, one line each, counts in words. Omit when empty.
4. Then, unless `--report-only`, one closing line that opens the walkthrough on the first `needs input` card already shown: `First up: {id}. Approve, skip, change, or "details" for the evidence, exact change, and rollback.` Do not repeat the card. When nothing needs input, end instead with `Say "retro rollback <id>" to undo any of these.`

With `--report-only`, end instead with: `Say "retro walkthrough" to go through these one at a time.`

A reader who only sees this message should know what happened, what changed, and what is being asked of them, without opening the report.

Nothing new is applied in this phase; auto-apply ran before it.
