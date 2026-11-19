# Step 5: Finish

**Who:** the parent, after the last round
**Input:** the batch branch, `record.md` (every round report), `state.json`
**Output:** a branch that merges into main and behaves as its rounds claim, Linear tickets for the defects, one draft PR with `--pr`, the final report, and a clean machine

For `discover`, and when no round built anything, skip to section 6; its report replaces `## Done` with one `## Slice` block per slice (anchor, why, candidates kept and dropped, conventions, patterns).

## 1. Catch up with main

`git fetch origin main`, then `git merge-tree --write-tree origin/main HEAD`. If it conflicts, `git rebase origin/main` (one branch, so one rebase), resolve, and re-run the specs of every round whose files conflicted. A clean trial merge needs no rebase. Record the base the branch ends on.

## 2. Validate the combined change

Skip with `--no-validate`, or when every round was `test-only`. Say which in the report.

Otherwise run `${CLAUDE_PLUGIN_ROOT}/workflows/validate/AGENTS.md` once against the batch branch (`<branch> in <repo>`), with freeform criteria built from the `app-code` rounds' **Behavior to validate** lines:

```
Each change below should behave exactly as on main, unless it is marked flagged.
- I-{n} {title}: {flows}. {unchanged | flagged: userVisible}
- …
Test-only rounds (not to explore): I-{n}, I-{m}, …
```

- The diff tells the tester where to look: the app code these rounds changed. Specs-only rounds get no exploration.
- Run it on its own, with no other test-heavy agent on the machine. Use one stack for the whole check (implement's launch conventions, the run's worktree if there is one).
- Validate tags each bug `introduced`, `pre-existing`, or `unconfirmed`. For each `introduced` bug, also name the round whose commits are on its repro path.

## 3. Fix what the branch broke

Implement's step 6 rules, scoped to this branch:

- **`introduced` bugs** (and `unconfirmed` ones whose repro runs through code a round changed): fix test-first, one commit per bug, message in user terms. Then `review --fix --since {SHA before the fixes}`, and `validate --check-only` with each fixed bug's repro as a criterion. Anything still failing goes under **Needs you**. Don't loop again.
- **A `flagged` round the human rejects later** is reverted with `git revert` of its commits, not rewritten.
- **`pre-existing` bugs** are not fixed here. They are defects (section 4).

## 4. File tickets

Two kinds, both per `templates/LINEAR-TICKET.md`. **Defects are filed automatically**; skip with `--no-file` and they are listed in the report instead. **Refactors too big for a round are proposed, never filed automatically**: they go in the report for the human to approve (section 6), and only an approved one becomes a ticket.

**What gets filed:** every bug this run found that is real and not this branch's to fix:

- candidates the rounds labeled `out` with `kind: defect`, created or reopened during this run (`run` matches);
- validate's `pre-existing` bugs, and its `unconfirmed` ones outside the branch's code;
- `Not fixed` items from the rounds' implement reports that describe wrong behavior.

**Refactors to propose:** `out` candidates with `kind: refactor` created during this run (`run` matches) and with no `ticket`. Draft each one now per the template (title, recommended approach and why, what gets easier, scope), but don't create it. The draft goes in the report under **Refactor tickets to file?**. A refactor the human skips stays `open` with no ticket and is proposed again in a later run only if new evidence adds to it.

**What doesn't:** `out` candidates with `kind: restricted` (structural work in a restricted area, not a bug); findings that cite the security report (`security-testing` owns those); anything with a `ticket` already. Search the Linear project for the improve ID and the title's key words before creating one, so a re-run doesn't file duplicates.

Write each ticket per `templates/LINEAR-TICKET.md` with the Linear MCP: the project, labels, priority by user impact, and **Needs validation first** for anything resting on `reading` alone, low confidence, or a console check nobody ran. Validate's bugs carry their repro. A bug validate found that matches an existing candidate is one ticket, not two.

Then write each filed ticket ID into `state.json` (`ticket`, and create a candidate for any validate bug that had none, `label: out`, `kind: defect`) and into `record.md`.

## 5. PR, only with `--pr`

1. **Reviewed HEAD.** `code-review/scripts/last-reviewed-sha.sh {repo} {branch}`. Exit 0: push. Otherwise run `review --fix --since {last reviewed SHA}` first. The push is its own Bash call, after the check.
2. Push the branch and open **one draft PR** against `main` (GitHub MCP, `draft: true`; fallback `gh pr create --draft`). Title: what the batch changes for the people who work in this code, e.g. `Tighten care request and referral tests, and share scheduled-message errors`.
3. Body, in the global PR format:
   - **Description:** 1-2 short paragraphs on what gets safer or easier, from the point of view of whoever benefits (users for a `flagged` change, the engineers who work in this code otherwise). No round-by-round list, no file walkthrough.
   - **Visuals:** the before/after screenshots of any `flagged` UI change. When nothing in the batch is visible, the heading becomes `### Checks`: a short list of what ran beyond CI (each round's review, before/after screenshot comparisons, validate's result and what it couldn't cover, and for performance rounds the measured before → after with the production p95 it targets). Leave out specs, lint, and types; CI already shows those.
   - No Claude attribution line.
4. Print the URL. Never mark it ready for review, and never merge.

Without `--pr`, the report's last line offers `pr`, which runs this section.

## 6. Report

One message, implement's closing-list shape, numbered across sections so the human answers by number:

```
## Done
{N} rounds · {N} built ({test-only} test-only, {app-code} app code, {flagged} flagged) · {N} parked · {lines} lines changed ({at last round} before the finish{, target {N}} with --loc) · branch {branch} on main @ {sha} · {PR url | local only}
validate: {N} criteria pass, {N} bugs fixed on the branch, {N} pre-existing | skipped: {why}
perf: {I-n {measure} {before → after} (production baseline {p95}); … | none}

| Round | Candidate | What changed | Commits |
|-------|-----------|--------------|---------|
| 1 | I-{n} | {one line, user terms} | {N} |

## Decisions I made
1. {flagged changes first: userVisible, payoff, before/after} …

## Needs you
{N}. {parked rounds and why, gate false positives, anything validate left failing, or "Nothing."}

## Tickets filed
| Ticket | Kind | Priority | Needs validation first? |
|--------|------|----------|-------------------------|
| [PROD-…](url) {title} | defect | {priority} | {yes: what to check | no} |

## Refactor tickets to file?
{N}. {title} · recommends {one PR | campaign}: {why, one clause} · ~{files} files · I-{n}

## Backlog
{top 5 open candidates}

Say ok to keep all of it, a number to change one, file to file every proposed refactor ticket (or file and the numbers), or pr to push and open a draft PR.
```

- Leave out **Refactor tickets to file?** when there are none.
- `file` (or `file 6 8`) creates those tickets per the template, with the Linear MCP, then records the IDs in `state.json` and `record.md` and prints them as links. `ok` alone files none of them.

## 7. Clean up

- Stop any stack the run started, and revert temporary edits it made in the worktree (a stack slot, `.pnp.cjs`, a `yarn install` lockfile change). Never touch the human's other worktrees or stacks.
- With `--worktree`: keep the worktree while the PR is a draft the human may want to try; give its path and the cleanup commands (`git worktree remove <path>`, `git branch -D <branch>` after merge). Remove `improve-parked/*` refs the human didn't ask to keep only after they've seen the report.
- Delete scratch files, finish `record.md`, and remove the lock.
