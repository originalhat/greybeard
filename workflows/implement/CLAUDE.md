# Implement Workflow

Turns a ticket or a set of requirements into working, tested, reviewed code on a branch — test-first, then reviewed and auto-fixed via `review-fix`.

## Directory Structure

```
implement/
└── CLAUDE.md    # You are here — the whole pipeline lives in this one file
```

No lenses or templates of its own. Step 5 reuses `review-fix` and `code-review` unmodified.

## Inputs

Triggered by **`/implement <ticket-or-requirements>`**, optionally **`in <repo>`** and/or **`--skip-ui`** (skip the render check in step 7) and/or **`--pr`** (push and open a draft PR in step 8).

- A JIRA ticket URL (`https://sanabenefits.atlassian.net/browse/ER-1477`) or bare ticket ID, a GitHub issue URL, or pasted freeform requirements.
- The target repo: explicit `in <repo>`, else inferred from the ticket, else the current working directory's repo.
- The `atlassian` MCP for JIRA tickets, `gh` for GitHub issues. Neither is needed for freeform requirements.

## Outputs

- A branch, local only, holding:
  - One implementation commit covering the tests and the code together (or a small number, if the requirements naturally split into independent pieces).
  - `review-fix`'s own auto-fix commits, unmodified from how that pipeline already commits.
  - One correction commit, if step 6 finds anything to fix.
- A closing summary: what was implemented, the design chosen and what was **not built** (step 2), what `review --fix` found and fixed, what's still open and needs a human, and the render-check result from step 7 (screenshot paths, or why it was skipped).
- No push and no PR unless `--pr` was passed. With `--pr`, the branch is pushed and a draft PR is opened with the closing summary as its body. Otherwise the branch stays local until the human decides it's ready.

## Execution

These steps are **strictly sequential** — later steps depend on earlier ones actually finishing, not just starting.

### 1. Intake

- Resolve the input:
  - JIRA ticket → `mcp__atlassian__getJiraIssue` (same pattern as `triage`) for title, description, acceptance criteria, linked issues.
  - GitHub issue → the GitHub MCP issue tool (fallback: `gh issue view {url} --json title,body`).
  - Freeform text → use as-is; if there's no clear, checkable behavior in it, ask before proceeding rather than inventing scope.
- Resolve the target repo and check it out under `$GREYBEARD_DATA/sources/{repo}/` (same convention as `review`).
- Check the current branch. If it's `main`/`master`, create a new branch named from the ticket ID or a short slug of the requirement (`er-1477`, `dark-mode-toggle`). If already on a feature branch, continue on it — this supports resuming a half-finished implementation rather than starting over.

### 2. Investigate

- Before writing anything: read the target repo's own `CLAUDE.md`/`AGENTS.md`, if present. Its testing framework, conventions, and style rules override generic defaults.
- Locate the relevant files, existing tests, and existing patterns for this kind of change. Use an `Explore` subagent for this on a large or unfamiliar repo; do it directly on a small, well-known one.
- Identify every distinct behavior the ticket/requirements imply. This list is what step 3 iterates over.
- If investigation surfaces a requirement that conflicts with existing behavior, or a genuinely ambiguous acceptance criterion, stop and ask — don't guess and build the wrong thing.
- **Design choice.** If the ticket admits more than one materially different implementation — a feature flag vs. a removal, a new model vs. a column, sync vs. async, a config table vs. a constant — pick the one with the smallest diff that satisfies the acceptance criteria. "Turn off for now" means remove, not gate. This is the repo rule "keep it simple, especially to start"; the human can ask for the bigger design after seeing the small one work. Write the alternative and one sentence on why it lost into the closing summary under **Not built**, never into the code. If the choice is genuinely a product call rather than a size call, ask before step 3.

### 3. TDD — red, then green, one behavior at a time

For each behavior identified in step 2:

- **Red:** write a test that exercises the behavior through its public interface — inputs and observable outputs or state, not internal calls or private methods. Run it and confirm it fails, and fails for the expected reason, not a typo or a setup error.
- **Green:** write the minimum code to make that test pass. Resist adding anything the current behavior doesn't require yet.
- **Refactor:** once green, clean up duplication or naming if needed, keeping the suite green throughout.
- Move to the next behavior. Don't write implementation code ahead of its test.

Test behavior, not implementation: assert on what the system does, not how it does it internally — no asserting a private method was called, no over-mocking a collaborator you could exercise for real. Follow the target repo's existing test style and framework rather than importing habits from elsewhere.

### 4. Commit

- Only once every behavior from step 2 is implemented. Run the target repo's **entire** existing test suite, not just the tests this step added — a change that passes its own new tests can still break something unrelated. Commit once all of it is green, not mid-loop.
- One commit covering the tests and the implementation together. Message describes the requirement, not the mechanics — `Add dark mode toggle to settings`, not `Add useState and CSS class`.

### 5. `review --fix`

- Follow `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md` exactly against this branch — the same pipeline plain `review --fix` runs, unmodified. This produces its own auto-fix commits and a final report of whatever's left.
- Progress messages: one line when `review --fix` starts and one when it finishes. Lens-by-lens and round-by-round status belongs in the fix-run record, not in chat. The same cap applies to the rest of this pipeline: no per-behavior or per-test narration; the closing summary is the report.

### 6. Correct what's left

- From `review --fix`'s final report, apply any remaining finding that's unambiguously in scope and doesn't require a product or design judgment call, then commit that separately from step 4 and from `review-fix`'s own commits.
- Leave anything that's a genuine judgment call — a naming preference, a scope question, "should this actually be here" — for the closing summary instead of guessing.
- When the change is reachable through a UI, mention in the closing summary that `validate` (`${CLAUDE_PLUGIN_ROOT}/workflows/validate/CLAUDE.md`) is the next step — this pipeline doesn't run it itself.

### 7. Render check, unless `--skip-ui`

A smoke check, not validation. `validate` walks the acceptance criteria; this step only confirms the pages this branch touched render and look like their neighbours.

- Applies when the diff touches a view, template, component, or stylesheet. Skip it outright for backend-only changes and say so in the summary. Skip it when the invocation carries `--skip-ui` (or "skip the UI check", "no browser").
- When it applies, spawn a subagent (model: `sonnet`) to:
  - Launch the app — check for a project-specific launch skill first (e.g. `run`), otherwise start it per the target repo's conventions.
  - Load each changed page once via the `playwright` MCP tools and take one screenshot per page. No clicking through flows, no criteria walkthrough.
  - Look at the screenshot next to the nearest existing page of the same kind (a list next to the queue list, a form next to an existing form) and report anything visibly off: spacing, row styling, icons, alignment, a component that did not render.
- If a page fails to render or is visibly inconsistent with its neighbours, fix that before the closing summary and re-check once. Anything that needs a design decision goes in the summary instead.
- Put the screenshot paths in the closing summary.

### 8. Draft PR, only with `--pr`

- Without `--pr`: end the closing summary with one line, `Say pr to push and open a draft PR.` Do nothing else.
- With `--pr` (or when the human says `pr` afterwards): push the branch to `origin` and open a **draft** PR against `main` with the GitHub MCP create-PR tool, `draft: true` (fallback: `gh pr create --draft`), title from the ticket, body = the closing summary with the **Not built** section included. Print the URL. Never mark it ready for review; that is the human's call.
- This is the only place in the greybeard workflows that pushes, and only on request.

## Notes

- **GitHub access: MCP first, `gh` as fallback.** Use the GitHub MCP tools (`mcp__GitHub__*`) for reading PRs, issues, files, reviews, and comments and for posting comments and reviews. They run inside Claude's process, so the Bash sandbox, its TLS proxy, and the keychain never get in the way. Fall back to the `gh` command only when the MCP is not connected yet (it starts through npx and can lag at session start); `gh` is excluded from the sandbox, so it works without a retry. Pushing local commits is always plain `git`; the MCP cannot push a branch.
- Never pushes and never opens a PR unless asked with `--pr` or a `pr` reply, and then only a draft — otherwise the same convention as `review --fix`. The human decides when the branch is ready for review.
- Never runs against a branch the user doesn't own — this pipeline commits as it goes, so it only ever runs on a branch you can write to, same reasoning as `review --fix`.
- If step 1 or step 2 turns up real ambiguity, stop and ask. Steps 3–8 assume the scope is already settled.
- Resuming: if the branch from a prior `/implement` run already exists with partial work, step 1 picks it up rather than starting over.
