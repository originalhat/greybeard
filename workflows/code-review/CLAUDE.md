# Code Review Workflow

A multi-stage, multi-modal code review pipeline that evaluates changes against technical lenses and repo-specific context.

## Directory Structure

```
code-review/
├── CLAUDE.md           # You are here
├── lenses/             # Generalized technical review criteria
├── context/            # Repo/team-specific review criteria
└── templates/          # Canonical output format
```

## Inputs

Triggered by **`review <github PR URL>`** (also accepts `review <branch-name> in <repo-name>` when there's no PR yet).

- A GitHub PR URL, or a branch to review (checked out under `../greybeard-data/sources/{repo}/`). From a PR URL, resolve the repo and branch.
- The diff against `origin/main`

## Outputs

A single impact-first report: a pass/fail/nit tally, then numbered failures. Each heading states the user-facing consequence; the body gives one sentence of context, then what goes wrong; a one-sentence **Fix** closes it. Written in Simplified Technical English at roughly a 10th grade reading level. Technical depth is held in context for follow-up, not printed.

**The format is defined in `templates/REPORT-FORMAT.md` and is not optional.** Read it before writing the report.

## Execution

### Model Tiers

- **Steps 5–6 (Evaluation):** Fast, economical mid-tier model (currently Sonnet) — pattern matching against lenses and context, fast and parallelizable
- **Steps 8–9 (Fact-Check, Cross-Repo):** Most capable available frontier model — requires judgment, cross-referencing, and contextual reasoning

### Steps

These steps are **strictly sequential** — do not start a step until all prior steps are complete.

1. **Setup**: Check out the branch under `../greybeard-data/sources/{repo}/`
2. **Fetch Latest**: Run `git fetch origin main` and `git fetch origin {branch}` to ensure refs are current
3. **Diff**: Use three-dot diff (`git diff origin/main...HEAD`) to see only branch changes, excluding unrelated changes merged to main after the branch was created
4. **PR Context** (optional): If a PR exists for the branch, fetch its title, description, and linked issues (`gh pr view {branch} --json title,body,url` or the GitHub MCP tools). Feed this as additional context to lens and context evaluation. Skip gracefully if no PR exists.
5. **Parallel Evaluation** (mid-tier model): Run each lens in `lenses/` against the diff (include PR context from step 4 if available). Steps 5 and 6 may run in parallel with each other. Each lens agent returns, per finding: the **consequence** (what breaks, for whom), the mechanism in one or two sentences, `file:line`, and a suggested fix — plus whether it rises above a nit. Lens agents report raw; they do not format.
6. **Context Evaluation** (mid-tier model): Run `context/` criteria against the diff (include PR context from step 4 if available)
7. **Report**: Aggregate findings from steps 5–6. Wait for both to complete before proceeding.
8. **Fact-Check** (frontier model): Verify each finding from step 7 in the actual repo to ensure contextual correctness. Do not start until step 7 is complete. Discard anything that doesn't hold up — an unconfirmed finding is dropped, not hedged.
9. **Cross-Repo Analysis** (frontier model): If needed, check related repos in `../greybeard-data/sources/` for breaking changes (see below)
10. **Final Summary**: Write the report per `templates/REPORT-FORMAT.md`. Retain each finding's `file:line`, call path, and suggested fix in context to answer follow-ups — none of it goes in the report.

### Cross-Repo Analysis

Before comparing against other repos in `../greybeard-data/sources/`:

1. **Pull latest main** for each related repo: `git -C ../greybeard-data/sources/{other-repo} checkout main && git -C ../greybeard-data/sources/{other-repo} pull`
2. Search for dependencies on changed interfaces (endpoints, types, etc.)
3. Verify whether dependencies still exist or have already been updated

## Components

### Lenses (`lenses/`)

Generalized technical patterns—not repo-specific. Each lens focuses on a single area:
- Security (auth, HIPAA/PHI)
- Performance (N+1 queries, React optimization)
- Correctness (type safety, idempotency)
- Architecture (separation of concerns, extensibility)

### Context (`context/`)

Repo and team-specific criteria:
- Known gotchas
- Style nits
- Business-specific patterns

### Templates (`templates/`)

`REPORT-FORMAT.md` — the canonical output format. Single source of truth, shared with the `/review` skill.

## Notes

- **Output format is fixed**: `templates/REPORT-FORMAT.md`. Impact in the heading, context then consequence in the body, one-sentence Fix, lens name in the footer. Number the failures, tally the passes, count the nits. Never enumerate all lenses.
- **No metaphors in findings.** No "blast radius", "retry storm", "footgun". Say what happens. Short active sentences, one term per concept.
- Lenses are designed to be quickly skimmable (all under 100 lines)
- Repos in `../greybeard-data/sources/` are not working environments—tests/console may not work
- **Always fetch before diffing**: `git fetch origin` ensures you have current refs
- **Use three-dot diff**: `git diff origin/main...HEAD` shows only branch changes; two-dot diff (`git diff origin/main`) includes unrelated changes merged to main and will produce misleading results
- **Pull related repos before cross-repo checks**: Stale local copies can cause false positives for breaking changes
