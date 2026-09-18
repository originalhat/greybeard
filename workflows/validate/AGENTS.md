# Validate Workflow

Drives a real browser against a running app to check a change against acceptance criteria, and — with `--exploratory` — follows up with bounded, loop-based exploratory testing beyond what was specified.

Split out of `implement`'s former "browser-validate" step so it can run standalone, against any branch, not just one `implement` just built, and so the exploratory-testing prompt can be tuned on its own without touching the implementation pipeline.

## Directory Structure

```
validate/
├── AGENTS.md                    # You are here
├── pipeline/
│   ├── 01-acceptance-check.md   # Drive the UI through each stated acceptance criterion
│   └── 02-exploratory.md        # Bounded, loop-based exploration beyond the stated criteria
└── templates/
    └── VALIDATION-REPORT.md     # Report format for both phases
```

## Inputs

Triggered by **`validate <ticket-or-requirements>`**, optionally **`in <repo>`**, optionally **`--exploratory`**.

- Same intake as `implement` step 1: a JIRA ticket URL/ID, a GitHub issue URL, or pasted freeform requirements — resolved to a concrete, numbered list of checkable acceptance criteria.
- The target repo: explicit `in <repo>`, else inferred from the ticket, else the current working directory's repo. Checked out under `$GREYBEARD_DATA/sources/{repo}/` (same convention as `review` and `implement`).
- Runs against whatever branch is currently checked out in that repo. Doesn't switch branches, doesn't require the change to have come from `implement` — this can validate anyone's branch, including one you didn't build.
- `--exploratory`: after the acceptance check, also run `pipeline/02-exploratory.md`'s bounded loop. Off by default — acceptance-only is the fast path and the common case.
- The `playwright` MCP tools, and either a project-specific launch skill (e.g. `run`) or the target repo's own conventions for starting the app.
- The `atlassian` MCP for JIRA tickets, `gh` for GitHub issues. Neither needed for freeform requirements.

## Outputs

- A pass/fail report per acceptance criterion, with what was actually observed in the browser — not a guess at whether the code should work.
- When `--exploratory` ran: a separate findings list for anything discovered outside the stated criteria (a bug, a broken state, a confusing UX path), each with repro steps, a severity, and a note on whether it's in scope for this change or pre-existing.
- A report at `$GREYBEARD_DATA/output/validate/{repo}/{branch}-{timestamp}.md`, per `templates/VALIDATION-REPORT.md`. One-shot audit record, not resumable state — there's no catch-up mode here.
- Never modifies code, never commits. Read-only against both the app and the repo.

## Execution

### Model Tiers

- **Acceptance check:** Sonnet — a mechanical walk of stated criteria as concrete user actions.
- **Exploratory loop:** Sonnet per round for the driving itself; Opus for the final synthesis pass that dedupes and ranks findings across rounds.

### Steps

These steps are **strictly sequential**.

1. **Intake**: Resolve the ticket/requirements input into a concrete, numbered list of checkable acceptance criteria — same resolution `implement` step 1 uses (JIRA / GitHub / freeform). If there's no clear, checkable behavior in the input, ask before proceeding rather than inventing criteria. Resolve the target repo and confirm it's checked out at `$GREYBEARD_DATA/sources/{repo}/` on the branch to validate.
2. **Scope check**: If the change isn't reachable through a UI — a cron job, a data migration, an internal API with no consumer yet — stop here and say so instead of forcing a browser check that can't mean anything.
3. **Launch**: Check for a project-specific launch skill first (e.g. `run`); otherwise start the app per the target repo's own conventions.
4. **Acceptance check** (`pipeline/01-acceptance-check.md`): One subagent drives the app via the `playwright` MCP tools through each criterion from step 1 as concrete user actions. Reports pass/fail per criterion, with what it actually saw.
5. **Exploratory loop, only if `--exploratory`** (`pipeline/02-exploratory.md`): Bounded rounds of open-ended probing around the change — adjacent flows, boundary inputs, state after navigation/reload, error paths — looking for anything the stated criteria didn't anticipate.
6. **Report**: Assemble the acceptance results and (if run) the exploratory findings into `templates/VALIDATION-REPORT.md`'s shape, print it, and write it to `$GREYBEARD_DATA/output/validate/{repo}/{branch}-{timestamp}.md`.

## Components

### Pipeline (`pipeline/`)

- **01-acceptance-check.md** — how to turn a stated criterion into a concrete browser action, and what counts as a pass vs. a fail vs. "couldn't verify."
- **02-exploratory.md** — the bounded loop: what "explore" means concretely, the round cap, and the stop condition. This is the part expected to need tuning against real runs — make changes here, not in this file.

### Templates (`templates/`)

- **VALIDATION-REPORT.md** — shared report format for acceptance-only and acceptance+exploratory runs.

## Notes

- Read-only against the app and the repo — never commits, never modifies code. If exploratory testing finds a bug worth fixing, that's a handoff back to `implement` or a manual fix, not something this workflow does itself.
- `implement` no longer runs this step itself — chain them explicitly: `implement <ticket>` to build it, then `validate <ticket>` once the branch exists.
- Skips outright, with a stated reason, for changes with no UI surface.
