# Phase 5: Apply

Only on the user's word. Three entry points: `retro walkthrough`, `retro apply <ids>`, `retro reject <ids> [reason]`, or a reply in the run's own thread.

## Walkthrough

Present open suggestions **one at a time**, in id order, overlapping ones together. For each:

1. Header: `Suggestion {n} of {open}: {id}, {short title}`.
2. Target, ladder rung, effort, confidence.
3. The magnitude line, then the verified evidence in two to four sentences with the user's own words quoted where they are the evidence.
4. The exact proposed change: text in a code block for prose and config; steps and file placement for skills and scripts.
5. Anything the user should know before deciding: overlaps, that a file is gitignored, that a repo has uncommitted work in the files you would touch, that a change alters a convention (first push in a workflow, for example).
6. One line: `Approve, skip, or tell me what to change.`

Then stop and wait. Accept partial approvals ("2 to 4 but not 1"), edits ("drop the last line", "production only"), and "not sure yet" (record `deferred`). Apply immediately on approval, record, commit, and present the next one in the same message.

## Applying

- Apply exactly what was approved, with the user's edits. Do not widen.
- **Before touching a repo**: `git -C <repo> status --short`. If files you need already carry uncommitted work from another thread, do not mix. Stage only your hunk against `HEAD` (`git show HEAD:<file>` + your edit + `git hash-object -w` + `git update-index --cacheinfo`), or, if your change depends on the uncommitted work, stop and ask whether to commit that work as its own item first. Never `git add -A`. Never switch branches in a shared checkout.
- **Skill or workflow changes** go in this repo, one commit per suggestion, following its convention. If the change adds a verb, flag, or output path, update the skill's `SKILL.md`, `workflows/CLAUDE.md`, the root `CLAUDE.md` data-directory tree, and `README.md` in the same commit, then run `skills/sync-local.sh`.
- **Config changes** to the user's settings may be refused by the permission classifier. Hand the user the exact JSON and mark the suggestion `accepted` once they confirm it is in.
- **Large suggestions**: write `$RETRO_HOME/designs/{id}-{slug}.md`, offer a ticket (Linear or Jira MCP), link the ticket from the design note, state, and changelog. Status `accepted`; the ticket tracks the work.
- **Sandbox-derived claims** about tool state (a token "invalid", a socket "denied") are re-checked outside the sandbox before being reported as broken.

## Recording

In `state.json`: `status` → `accepted` | `rejected` | `deferred`, `resolvedAt`, `reason` (what was applied, how it deviated from the proposal, or why it was skipped; for rejections keep the user's reason so the pattern is not re-proposed), `commits` (repo → sha), `ticket` if any.

In `$RETRO_HOME/CHANGELOG.md`, newest first under today's date: `- **{id}** {target}: {what changed in one line}. {Deviation from proposal, if any}. {Repo and sha, pushed or not}.`

## Commits

- `RETRO_HOME` repo: one path-scoped commit per suggestion, message `{id}: {short summary}`, then push if a remote exists.
- Other repos: one commit per suggestion, path-scoped, on that repo's usual branch convention. **Never push another repo** unless the user says to. When a repo has unpushed retro commits at the end of a walkthrough, list them.

## Closing a walkthrough

When nothing is `proposed`: list what changed by repo with shas, what was skipped and why, what is deferred, and any unpushed repos. If the walkthrough surfaced a correction to this workflow itself (a misread pattern, a missing check), fix `workflows/retro/` in the same session and say so.
