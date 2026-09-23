# Phase 5: Apply

High-confidence suggestions are applied during the run, optimistically, and reported; the user reviews them afterwards and rolls back what they do not want. Low-confidence suggestions are applied only on the user's word, through `retro walkthrough`, `retro apply <ids>`, `retro reject <ids> [reason]`, or a reply in the run's own thread.

## Auto-apply

Runs in a `retro` run right after synthesis (phase 3) and before the report (phase 4), so the report states what already changed. `--report-only` skips it. It covers both high-confidence quadrants, high value first, then low value.

A suggestion is auto-applied only when all of these hold; otherwise it goes to the walkthrough, and the report says which rule sent it there:

- Confidence is `high` (`03-synthesize.md` step 6), and effort is `small` or `medium`. `large` gets a design note and a ticket offer, never an edit.
- The change is local and has a one-step rollback: a path-scoped commit in a git repo, or, for a file outside git, a backup copy under `$RETRO_HOME/backups/{id}/` with a restore command.
- It does nothing outward-facing: no push to any repo but `RETRO_HOME`, no PR, ticket, comment, or message to a person, nothing against staging or production, no credential rotation, no deleted data.
- The proposed change carries no open choice for the user ("say if it should be narrower" means it is not ready to apply).
- It does not revisit a `rejected` or `rolled-back` suggestion, and its target files have no uncommitted work from another thread.

For each one:

1. Apply exactly the proposed change.
2. Run its **How we'll know** check. If the check fails, undo the change, and send the suggestion to the walkthrough with what the check printed.
3. Commit it, one path-scoped commit per suggestion, message `{id}: {short summary}` (skill or workflow changes follow the repo rules under Applying below). Push only `RETRO_HOME`.
4. Record it: `status: accepted`, `autoApplied: true`, `resolvedAt`, `commits`, `rollback` (the exact command), and the check's result in `reason`. Add a changelog line marked `auto`.

When the sandbox or the permission classifier refuses a write, do not route around it. Leave the change unapplied, set `status: handed-off`, write the exact commands for the user into the report and the final message, and let phase 1 of the next run check whether it landed.

## Rollback

`retro rollback <ids>` undoes auto-applied or approved suggestions. Run each recorded `rollback` step (a `git revert` of the recorded commit, or restoring the backup), confirm the target matches its state before the change, and push `RETRO_HOME` if it changed. Record `status: rolled-back`, `resolvedAt`, and the user's reason if they gave one; a rolled-back suggestion is never re-applied automatically and is re-proposed only with new evidence and the rollback reason addressed. Changelog line: `- **{id}** rolled back: {reason}.`

## Walkthrough

The walkthrough covers what auto-apply did not: the low-confidence quadrants, high-confidence suggestions sent back by a rule above, and `handed-off` items still waiting on the user. Present open suggestions **one at a time**, in quadrant order (high value · high confidence, high value · low confidence, low value · high confidence, low value · low confidence), then id order within a quadrant, overlapping ones together. Each one is presented in the shape of `templates/SUGGESTION.md`, the same shape the report used:

1. Header: `Suggestion {n} of {open}: {id}, {short title}`, then the line with value, confidence, rung, effort, target.
2. The magnitude line, ending in time lost.
3. **Before**, **After**, **How we'll know**. This is the impact; it comes before the evidence and the change, and it is never skipped.
4. The verified evidence in two to four lines, the user's own words quoted where they are the evidence.
5. The exact change: text in a code block for prose and config; steps and file placement for skills and scripts.
6. **Rollback**, and **Before you decide**: overlaps, a gitignored file, uncommitted work in the files you would touch, a convention this changes.
7. One line: `Approve, skip, or tell me what to change.`

Then stop and wait. Accept partial approvals ("2 to 4 but not 1"), edits ("drop the last line", "production only"), and "not sure yet" (record `deferred`). Apply immediately on approval, record, commit, and present the next one in the same message.

## Applying

- Apply exactly what was approved, with the user's edits. Do not widen.
- **Before touching a repo**: `git -C <repo> status --short`. If files you need already carry uncommitted work from another thread, do not mix. Stage only your hunk against `HEAD` (`git show HEAD:<file>` + your edit + `git hash-object -w` + `git update-index --cacheinfo`), or, if your change depends on the uncommitted work, stop and ask whether to commit that work as its own item first. Never `git add -A`. Never switch branches in a shared checkout.
- **Skill or workflow changes** go in this repo, one commit per suggestion, following its convention. If the change adds a verb, flag, or output path, update the skill's `SKILL.md`, `workflows/AGENTS.md`, the root `CLAUDE.md` data-directory tree, and `README.md` in the same commit, then run `skills/sync-local.sh`.
- **Config changes** to the user's settings may be refused by the permission classifier. Hand the user the exact change, mark the suggestion `handed-off`, and let phase 1 of the next run verify it landed; the user can also confirm in the thread.
- **Large suggestions**: write `$RETRO_HOME/designs/{id}-{slug}.md`, offer a ticket (Linear or Jira MCP), link the ticket from the design note, state, and changelog. Status `accepted`; the ticket tracks the work.
- **Sandbox-derived claims** about tool state (a token "invalid", a socket "denied") are re-checked outside the sandbox before being reported as broken.

## Recording

In `state.json`: `status` → `accepted` | `handed-off` | `rejected` | `deferred` | `rolled-back`, `autoApplied` (true only for auto-apply), `rollback`, `resolvedAt`, `reason` (what was applied, how it deviated from the proposal, or why it was skipped; for rejections keep the user's reason so the pattern is not re-proposed), `commits` (repo → sha), `ticket` if any.

In `$RETRO_HOME/CHANGELOG.md`, newest first under today's date: `- **{id}** {target}: {what changed in one line}. {Deviation from proposal, if any}. {Repo and sha, pushed or not}.`

## Commits

- `RETRO_HOME` repo: one path-scoped commit per suggestion, message `{id}: {short summary}`, then push if a remote exists.
- Other repos: one commit per suggestion, path-scoped, on that repo's usual branch convention. **Never push another repo** unless the user says to. When a repo has unpushed retro commits at the end of a walkthrough, list them.

## Closing a walkthrough

When nothing is `proposed`: list what changed by repo with shas, what was skipped and why, what is deferred, and any unpushed repos. If the walkthrough surfaced a correction to this workflow itself (a misread pattern, a missing check), fix `workflows/retro/` in the same session and say so.
