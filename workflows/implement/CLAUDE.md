# Implement Workflow

Turns a ticket or a set of requirements into working, tested, reviewed code on a branch — test-first, then reviewed and auto-fixed via `review-fix`.

## Directory Structure

```
implement/
└── CLAUDE.md    # You are here — the whole pipeline lives in this one file
```

No lenses or templates of its own. Step 5 reuses `review-fix` and `code-review` unmodified.

## Inputs

Triggered by **`/implement <ticket-or-requirements>`**, optionally **`in <repo>`**.

- A JIRA ticket URL (`https://sanabenefits.atlassian.net/browse/ER-1477`) or bare ticket ID, a GitHub issue URL, or pasted freeform requirements.
- The target repo: explicit `in <repo>`, else inferred from the ticket, else the current working directory's repo.
- The `atlassian` MCP for JIRA tickets, `gh` for GitHub issues. Neither is needed for freeform requirements.

## Outputs

- A branch, local only, holding:
  - One implementation commit covering the tests and the code together (or a small number, if the requirements naturally split into independent pieces).
  - `review-fix`'s own auto-fix commits, unmodified from how that pipeline already commits.
  - One correction commit, if step 6 finds anything to fix.
- A closing summary: what was implemented, what `review --fix` found and fixed, and what's still open and needs a human.
- Never a push, never a PR. The branch stays local until the human decides it's ready.

## Execution

These steps are **strictly sequential** — later steps depend on earlier ones actually finishing, not just starting.

### 1. Intake

- Resolve the input:
  - JIRA ticket → `mcp__atlassian__getJiraIssue` (same pattern as `triage`) for title, description, acceptance criteria, linked issues.
  - GitHub issue → `gh issue view {url} --json title,body`.
  - Freeform text → use as-is; if there's no clear, checkable behavior in it, ask before proceeding rather than inventing scope.
- Resolve the target repo and check it out under `$GREYBEARD_DATA/sources/{repo}/` (same convention as `review`).
- Check the current branch. If it's `main`/`master`, create a new branch named from the ticket ID or a short slug of the requirement (`er-1477`, `dark-mode-toggle`). If already on a feature branch, continue on it — this supports resuming a half-finished implementation rather than starting over.

### 2. Investigate

- Before writing anything: read the target repo's own `CLAUDE.md`/`AGENTS.md`, if present. Its testing framework, conventions, and style rules override generic defaults.
- Locate the relevant files, existing tests, and existing patterns for this kind of change. Use an `Explore` subagent for this on a large or unfamiliar repo; do it directly on a small, well-known one.
- Identify every distinct behavior the ticket/requirements imply. This list is what step 3 iterates over.
- If investigation surfaces a requirement that conflicts with existing behavior, or a genuinely ambiguous acceptance criterion, stop and ask — don't guess and build the wrong thing.

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

### 6. Correct what's left

- From `review --fix`'s final report, apply any remaining finding that's unambiguously in scope and doesn't require a product or design judgment call, then commit that separately from step 4 and from `review-fix`'s own commits.
- Leave anything that's a genuine judgment call — a naming preference, a scope question, "should this actually be here" — for the closing summary instead of guessing.
- When the change is reachable through a UI, mention in the closing summary that `validate` (`${CLAUDE_PLUGIN_ROOT}/workflows/validate/CLAUDE.md`) is the next step — this pipeline doesn't run it itself.

## Notes

- Never pushes and never opens a PR — same convention as `review --fix`. The human decides when the branch is ready.
- Never runs against a branch the user doesn't own — this pipeline commits as it goes, so it only ever runs on a branch you can write to, same reasoning as `review --fix`.
- If step 1 or step 2 turns up real ambiguity, stop and ask. Steps 3–6 assume the scope is already settled.
- Resuming: if the branch from a prior `/implement` run already exists with partial work, step 1 picks it up rather than starting over.
