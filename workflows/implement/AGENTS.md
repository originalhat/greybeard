# Implement Workflow

Turns a ticket or a set of requirements into working, tested, reviewed, and validated code on a branch: test-first, then code review and QA on the same commit, one fix pass, a review of only the fixes, and one list of decisions for the human at the end.

## Directory Structure

```
implement/
├── AGENTS.md                  # You are here — the whole pipeline lives in this one file
└── templates/
    └── AGENT-SUMMARY.md       # Point-of-record summary attached to the Linear ticket (step 10)
```

No lenses of its own. Steps 5–7 reuse `code-review`, `review-fix`, and `validate` unmodified.

## Inputs

Triggered by **`/implement <ticket-or-requirements>`**, optionally **`in <repo>`** and/or **`--worktree`** (work in a sibling git worktree with its own local stack, step 1) and/or **`--base <branch>`** (with `--worktree`, start the new branch from this branch instead of `main`, for stacked work) and/or **`--skip-ui`** (no render check, and validate drives no browser, step 5) and/or **`--no-validate`** (skip validate, step 5) and/or **`--pr`** (push and open a draft PR in step 9).

- A Linear issue URL or identifier (`PROD-1234`), a JIRA ticket URL (`https://sanabenefits.atlassian.net/browse/ER-1477`) or bare ticket ID, a GitHub issue URL, or pasted freeform requirements.
- The target repo: explicit `in <repo>`, else inferred from the ticket, else the current working directory's repo.
- The `Linear` MCP for Linear issues, the `atlassian` MCP for JIRA tickets, `gh` for GitHub issues. None is needed for freeform requirements.

## Outputs

- A branch, local only, holding:
  - One implementation commit covering the tests and the code together (or a small number, if the requirements naturally split into independent pieces).
  - Step 6's fix commits: `review-fix`'s own auto-fix commit, one commit per validate bug fixed, and one commit for the recommendations it took.
  - `review-fix`'s commits from step 7, if the fixes needed any.
- A review run record and, unless validate was skipped, a validate report and run record, each in its usual place under `$GREYBEARD_DATA/output/`.
- A closing summary that is one list (step 8): what changed, the decisions taken on the human's behalf, what needs them, what was **not built**, and what was not fixed.
- For a Linear issue, an `agent-summary.md` attached to the issue as the point of record (step 10).
- No push and no PR unless `--pr` was passed. With `--pr`, the branch is pushed and a draft PR is opened with a short Description + Visuals body (step 9). Otherwise the branch stays local until the human decides it's ready.
- With `--worktree`: the worktree path, and when the repo provides a per-worktree stack, its app URL and the teardown command. The worktree and its stack are left running for the human.

## Execution

These steps are **strictly sequential** — later steps depend on earlier ones actually finishing, not just starting.

**Ask early or not at all.** The human almost always takes the agent's recommendation after review and QA. So the run stops mid-way only for a question that changes what gets built (steps 1 and 2). Everything else is decided in step 6 and listed in step 8. On care_platform 2423, 4 of 5 mid-run answers were review `ask-user` items. The commits they caused produced 2 of validate's 3 bugs and a 28-minute re-review.

### 1. Intake

- Resolve the input:
  - Linear issue → `mcp__Linear__get_issue` for title, description, `gitBranchName`, and attachments. A bare `ABC-123` ID is Linear unless it is an `ER-` ticket or the Linear lookup misses, then try JIRA.
  - JIRA ticket → `mcp__atlassian__getJiraIssue` (same pattern as `triage`) for title, description, acceptance criteria, linked issues.
  - GitHub issue → the GitHub MCP issue tool (fallback: `gh issue view {url} --json title,body`).
  - Freeform text → use as-is; if there's no clear, checkable behavior in it, ask before proceeding rather than inventing scope.
- Resolve the target repo (see Inputs). Without `--worktree`, work in its existing checkout. With `--worktree`, see the worktree section below and skip the next bullet.
- Check the current branch. If it's `main`/`master`, create a new branch: the Linear issue's `gitBranchName` as-is (Linear links the branch and its PR to the issue from that name), else the ticket ID or a short slug of the requirement (`er-1477`, `dark-mode-toggle`). If already on a feature branch, continue on it — this supports resuming a half-finished implementation rather than starting over.

#### With `--worktree`

The main checkout is never switched, edited, or used to run this branch's tests; other work may be running from it.

- Branch name as above (the Linear `gitBranchName`, else the ticket ID or a slug). Worktree path: a sibling of the main checkout named `<checkout-dir>-<suffix>`, where the suffix is the ticket number (`care_platform-2139`), else the branch name without its `d/` prefix. It must stay under `$HOME` so the Docker VM can mount it.
- Base: `--base <branch>` if given, else `main`. If that path already exists on that branch, resume in it. Otherwise `git -C <main checkout> fetch origin <base>`, then `git -C <main checkout> worktree add --no-track -b <branch> <path> origin/<base>`, or `git -C <main checkout> worktree add <path> <branch>` when the branch already exists locally. `--no-track` keeps the new branch from treating the base as its upstream.
- With `--base`, the branch is stacked: review (steps 5 and 7) and the reviewed-SHA check cover `origin/<base>..HEAD` only, not the parent's commits; validate is left for the whole stack (step 8); and the draft PR (step 9) targets `<base>` instead of `main`. `git worktree` and `docker` commands need the Bash sandbox off; inside it, checkouts come out half-written.
- Copy untracked agent instruction files that git leaves behind, `CLAUDE.local.md` today, from the main checkout into the worktree when the worktree lacks them, then read them as step 2 would.
- If the repo has an executable `bin/worktree-setup`, run it from the worktree and keep the app URL it prints. Warnings in its output are fine; a non-zero exit stops the run with its output in the summary. If the script doesn't exist, carry on with a bare worktree and the repo's usual test conventions.
- From here on, every step runs from the worktree path: edits, tests, commits, review, the render check, validate, and the push.

### 2. Investigate

- Before writing anything: read the target repo's own `CLAUDE.md`/`AGENTS.md`, if present. Its testing framework, conventions, and style rules override generic defaults.
- Locate the relevant files, existing tests, and existing patterns for this kind of change. Use an `Explore` subagent for this on a large or unfamiliar repo; do it directly on a small, well-known one.
- Identify every distinct behavior the ticket/requirements imply. This list is what step 3 iterates over.
- If investigation surfaces a requirement that conflicts with existing behavior, or an acceptance criterion with two readings that lead to different features, stop and ask — don't guess and build the wrong thing. Ask every such question in one message. Smaller gaps (copy, an empty state, a narrow screen, who else can see it) are not questions: pick the smallest reasonable answer, build it, and list it in step 8 as a decision.
- **Design choice.** If the ticket admits more than one materially different implementation — a feature flag vs. a removal, a new model vs. a column, sync vs. async, a config table vs. a constant — pick the one with the smallest diff that satisfies the acceptance criteria. "Turn off for now" means remove, not gate. This is the repo rule "keep it simple, especially to start"; the human can ask for the bigger design after seeing the small one work. Write the alternative and one sentence on why it lost into the closing summary under **Not built**, never into the code. If the choice is genuinely a product call rather than a size call, ask before step 3.

### 3. TDD — red, then green, one behavior at a time

For each behavior identified in step 2:

- **Red:** write a test that exercises the behavior through its public interface — inputs and observable outputs or state, not internal calls or private methods. Run it and confirm it fails, and fails for the expected reason, not a typo or a setup error.
- **Green:** write the minimum code to make that test pass. Resist adding anything the current behavior doesn't require yet.
- **Refactor:** once green, clean up duplication or naming if needed, keeping the suite green throughout.
- Move to the next behavior. Don't write implementation code ahead of its test.

Test behavior, not implementation: assert on what the system does, not how it does it internally — no asserting a private method was called, no over-mocking a collaborator you could exercise for real. Follow the target repo's existing test style and framework rather than importing habits from elsewhere.

### 4. Commit

- Only once every behavior from step 2 is implemented. Run the tests for the files this change touched and the existing specs that cover them, not just the tests this step added. Leave the whole suite to the repo's CI when it has one (care_platform, origami_claims, and home all do); run it locally only when the repo has no CI, or when the change is cross-cutting (a shared model, a migration, a config file). Commit once those are green, not mid-loop.
- With `--worktree` and a per-worktree stack, run tests in that stack from the worktree, never in the main checkout's containers. Always pass `-T` to `docker compose exec` (agent shells have no TTY). Scope frontend tests to the covering files, e.g. `docker compose exec -T care_assets yarn jest --maxWorkers=2 <files>`, rather than a full-suite command like `yarn precommit`; jest inside the asset watcher roughly doubles its memory.
- One commit covering the tests and the implementation together. Message describes the requirement, not the mechanics — `Add dark mode toggle to settings`, not `Add useState and CSS class`.

### 5. Evaluate: review, then validate

Both look at the step 4 commit, the **evaluated SHA**, and nothing commits between them. Fixes wait for step 6, so one fix pass and one scoped re-review cover everything both found. On care_platform 2423, fixes landed between review and validate, and a second full review ran over all of it: 69 minutes of review and 38 of validate before the push.

Run them one after the other, in this order:

1. **Review.** Run the `review` pipeline (`${CLAUDE_PLUGIN_ROOT}/workflows/code-review/AGENTS.md`) as a plain review that only reports, not `--fix`. Its run record marks the evaluated SHA as reviewed.
2. **Render check**, unless `--skip-ui` or the diff touches no view, template, component, or stylesheet. A smoke check, not validation: one Sonnet subagent loads each changed page once and takes one screenshot per page.
   - Launch the app. With `--worktree` and a per-worktree stack, use the app URL from step 1 (it's already running). Otherwise check for a project-specific launch skill first (e.g. `run`), else start it per the target repo's conventions.
   - With `--worktree`: if the branch changed the stack's build or env config (`client/start.mjs`, `.env`, `docker-compose.yml`), restart the worktree's asset watcher from the worktree (`docker compose restart care_assets`, or `docker compose up -d` for compose changes) and wait for the rebuilt bundle before loading pages, or the screenshot shows the old build.
   - Sign in with the repo's local dev login (care_platform: `POST /api/sessions` with a seed user's `{email}`).
   - Prefix screenshot filenames with the branch slug, copy them to thread storage, and delete the originals from the browser tool's own output folder (the Playwright MCP writes to `<main checkout>/.playwright-mcp/`).
   - No clicking through flows. Look at each screenshot next to the nearest existing page of the same kind (a list next to the queue list, a form next to an existing form) and report anything visibly off: spacing, row styling, icons, alignment, a component that did not render.
3. **Validate**, unless skipped (below). Run `${CLAUDE_PLUGIN_ROOT}/workflows/validate/AGENTS.md` against the branch with the ticket's criteria, using the app the render check launched. It writes its own report and run record. With `--skip-ui`, tell it not to drive a browser; it still uses HTTP and the local console.

- **Validate is skipped** with `--no-validate`; for a stacked branch (`--base`), because the stack is validated once from its top branch (step 8 says how); and when validate's step 2 finds nothing in the change it can exercise locally. Say which in the summary.
- With `--worktree`, all three run against the worktree. Don't check the branch out under `$GREYBEARD_DATA/sources/`, and ignore the review docs' `cd` into it. Give every lens, fixer, and gate agent the worktree path and the exact diff command, `git diff origin/<base>...HEAD` (`<base>` is `main` without `--base`). Record `Base: origin/<base> @ <sha>` in run records. Fixers commit in the worktree. Keep rspec and docker out of lens agents.
- Progress: one line as each of the three starts and one when it finishes. No per-lens, per-round, per-behavior, or per-test narration anywhere in this pipeline; the closing summary is the report.

### 6. One fix pass

Everything step 5 found is fixed together, before any re-review.

- **Review findings.** Classify them with `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/pipeline/01-triage.md`, then apply the `auto-fix` ones with `pipeline/02-fixer.md`. Its `review-fix:` commit is unchanged from how that pipeline commits.
- **Validate bugs.** Fix test-first, as in step 3, every bug the branch `introduced`, and every `unconfirmed` one whose repro runs through code this branch changed. Severe and moderate always; minor when the fix stays inside the changed area. One commit per bug, with the message in user terms (`Keep a sent message out of Drafts after Back`). Pre-existing and `couldn't reproduce` bugs go to the summary unfixed.
- **Render-check problems.** Fix a page that fails to render or looks visibly off from its neighbours.
- **Decisions, taken optimistically.** For every `ask-user` finding and every validate question, take the recommendation you would give the human, as long as it stays inside the ticket's scope and a follow-up commit could undo it. Most often the recommendation is to leave the behavior as built, and nothing changes. When it is a change, make it test-first and put all of them in one `Apply review and QA recommendations` commit. Record every decision for step 8 either way, with what prompted it. Never take one of these optimistically; they wait for the human under **Needs you**:
  - a change to which record a value is read from, or which event triggers a behavior;
  - a new table, column, or other durable state;
  - anything resting on a `pending console check`;
  - a product call between two different features.
- Run the tests for the files this step touched, as in step 4.

### 7. Re-review and re-check

- **`review --fix`** per `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/AGENTS.md`. Its scope check usually reports `scoped <evaluated SHA>`, so it reviews only step 6's commits, capped at 2 rounds. Skip it when step 6 made no commits; the step 5 review record already covers HEAD.
- **Re-check**, when step 6 fixed a validate bug or changed anything a user sees: `validate --check-only` with the original criteria plus each fixed bug's repro as a criterion, its expected result the fixed behavior. A criterion that now fails gets one more test-first fix and one more `review --fix`. Anything still failing after that goes under **Needs you**. Don't loop again.

### 8. Closing summary: one list

The run's one stop for the human, outside the scope questions in steps 1 and 2. Everything that would have been a mid-run question is here, already decided where it could be.

```
## Done
{1-3 sentences: what the user can do now} · {N} commits · review: {N} auto-fixed ({scoped | full}) · validate: {N}/{N} criteria pass, {N} bugs fixed, {N} open · {screenshot paths}

## Decisions I made
1. {the decision, in user terms}. {why, one clause} ↳ {review #N | validate Q#N | ticket silent}

## Needs you
{N}. {only what step 6 could not decide, or "Nothing."}

## Not built
- {the alternative from step 2, and why it lost}

## Not fixed
- {pre-existing and couldn't-reproduce bugs, one line each}

Say ok to keep all of it, a number to change one, or pr to push and open a draft PR.
```

- Number decisions and needs in one run, so any of them can be answered by number.
- With `--worktree`: add the worktree path, the app URL, and how to clean up (`bin/worktree-teardown` from the worktree, then `git worktree remove <path>`, plus `git branch -D <branch>` once the branch is merged or abandoned). Don't tear it down; the human uses it to try the change.
- With `--base` (stacked): add one line, `Validate the stack once its last branch is built: validate --stack <top-branch> in <repo>`.

### 9. Draft PR, only with `--pr`

- Without `--pr`: step 8's last line is the offer. Do nothing else.
- With `--pr` (or when the human says `pr` afterwards): **first make sure HEAD is reviewed.** Run `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/scripts/last-reviewed-sha.sh {repo} {branch}` from the checkout (with `--base`, prefix it with `REVIEW_BASE=origin/<base>`). Exit 0: HEAD is the SHA the newest run record reviewed; push. Exit 1 or 2: commits landed since the last review, or no review was recorded; run `review --fix` (its scope check keeps it to the new commits), then re-check, then push. Say in one line which SHA was reviewed. The same check runs before **every** later push from this thread (`push it`, a rebase, fixes after review comments): a push is never the first thing that happens to a commit. Then push the branch to `origin` and open a **draft** PR against `main` (`<base>` when stacked) with the GitHub MCP create-PR tool, `draft: true` (fallback: `gh pr create --draft`), title from the ticket's title with no ticket ID or number in it (the branch name already links it), body in the global `Pull request descriptions` format: a `### Description` of 1-2 short paragraphs on the user need and experience, then `### Visuals` holding the render-check screenshot of the core functionality if one was captured (else left empty). Step 8's decisions, open items, and review and validate results stay in chat, not the PR body. No Claude attribution line. Print the URL. Never mark it ready for review; that is the human's call.
- This is the only place in the greybeard workflows that pushes, and only on request.

### 10. Attach `agent-summary.md` to the Linear issue

Only when the input was a Linear issue. Runs after step 9, without asking: the ticket is the durable record of how and why this change was made, for anyone investigating it later.

- Fill `templates/AGENT-SUMMARY.md` from this run: the closing summary, the design choice and **Not built**, every decision from step 6 and every answer or steer from the human and what prompted it, the tests, the review and validate results, the commits. Write it to `$TMPDIR/agent-summary.md`.
- **PHI-free.** Linear is not a BAA'd system. No member, dependent, or patient names, IDs, DOBs, or production URLs; describe data by shape. Check the file before uploading.
- Upload with `mcp__Linear__prepare_attachment_upload` (`filename: agent-summary.md`, `contentType: text/markdown`, exact byte size), then `curl -X PUT --data-binary @"$TMPDIR/agent-summary.md"` to the signed URL with every returned header verbatim (list the URL's host in `allowed_domains`; the URL expires in 60 seconds), then `mcp__Linear__create_attachment_from_upload` with title `agent-summary.md`.
- One summary per issue. If `get_issue`'s attachments already hold an `agent-summary.md` (a resumed run), upload the new one, then `mcp__Linear__delete_attachment` the old one.
- If the thread adds commits later (an answer from step 11, fixes after review comments), replace the attachment the same way after the push, so it describes what shipped.
- If the Linear MCP is not connected or the upload fails, say so in one line and leave the file path in the closing summary. Never block the rest of the pipeline on it.

### 11. When the human answers

- `ok`: nothing changes. `pr`: step 9.
- A number with a different answer: make that change test-first and commit it, one commit for the whole reply. Then `review --fix` (scoped to the new commit by its scope check), and `validate --check-only` on the affected criteria when a user would see the change. Print only what changed, in step 8's shape. Replace the Linear summary per step 10.
- An answer that extends the ticket's scope, or two answers that conflict: ask once before building.

## Notes

- **GitHub access: MCP first, `gh` as fallback.** Use the GitHub MCP tools (`mcp__GitHub__*`) for reading PRs, issues, files, reviews, and comments and for posting comments and reviews. They run inside Claude's process, so the Bash sandbox, its TLS proxy, and the keychain never get in the way. Fall back to the `gh` command only when the MCP is not connected yet (it starts through npx and can lag at session start); `gh` is excluded from the sandbox, so it works without a retry. Pushing local commits is always plain `git`; the MCP cannot push a branch.
- **Review each branch, validate each stack.** Every branch gets its own review, stacked or not. A stack, or a batch of tickets built on top of each other, is validated once from its top branch with `validate --stack`, which tags each bug with the branch that introduced it. Fix it on that branch with `implement` (it resumes the branch), then rebase the branches above it.
- **Re-reviews cover only what's new.** `review-fix` runs `code-review/scripts/review-scope.sh` first. After the first review, a few new commits get a scoped review of just those commits, not three more full rounds over the whole branch.
- **Push only from a reviewed SHA.** `scripts/last-reviewed-sha.sh` in the code-review workflow is the check; it reads the newest `HEAD SHA:` / `Final SHA:` from the branch's run records. On care_platform #980 one 193-line commit from acceptance testing and one 1000-line remodel each went out unreviewed, and every finding the human reviewers blocked on was in those commits.
- Never pushes and never opens a PR unless asked with `--pr` or a `pr` reply, and then only a draft — otherwise the same convention as `review --fix`. The human decides when the branch is ready for review.
- Never runs against a branch the user doesn't own — this pipeline commits as it goes, so it only ever runs on a branch you can write to, same reasoning as `review --fix`.
- If step 1 or step 2 turns up real ambiguity, stop and ask. Steps 3–7 assume the scope is already settled; anything they raise waits for step 8's list.
- Resuming: if the branch from a prior `/implement` run already exists with partial work, step 1 picks it up rather than starting over. With `--worktree`, that includes an existing worktree for the branch; re-running `bin/worktree-setup` there is safe.
