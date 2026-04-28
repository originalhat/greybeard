# Code Review Workflow

A multi-stage, multi-modal code review pipeline that evaluates changes against technical lenses and repo-specific context.

## Directory Structure

```
code-review/
├── CLAUDE.md           # You are here
├── lenses/             # Generalized technical review criteria
└── context/            # Repo/team-specific review criteria
```

## Inputs

- A branch to review (checked out under `../greybeard-data/sources/{repo}/`)
- The diff against `origin/main`

## Outputs

- A concise summary with PASS/FAIL per lens
- Issue descriptions with location and potential fix for any failures

## Execution

### Model Tiers

- **Steps 5–6 (Evaluation):** Sonnet — pattern matching against lenses and context, fast and parallelizable
- **Steps 8–9 (Fact-Check, Cross-Repo):** Opus — requires judgment, cross-referencing, and contextual reasoning

### Steps

These steps are **strictly sequential** — do not start a step until all prior steps are complete.

1. **Setup**: Check out the branch under `../greybeard-data/sources/{repo}/`
2. **Fetch Latest**: Run `git fetch origin main` and `git fetch origin {branch}` to ensure refs are current
3. **Diff**: Use three-dot diff (`git diff origin/main...HEAD`) to see only branch changes, excluding unrelated changes merged to main after the branch was created
4. **PR Context** (optional): If a PR exists for the branch, fetch its title, description, and linked issues (`gh pr view {branch} --json title,body,url` or the GitHub MCP tools). Feed this as additional context to lens and context evaluation. Skip gracefully if no PR exists.
5. **Parallel Evaluation** (Sonnet): Run each lens in `lenses/` against the diff (include PR context from step 4 if available). Steps 5 and 6 may run in parallel with each other.
6. **Context Evaluation** (Sonnet): Run `context/` criteria against the diff (include PR context from step 4 if available)
7. **Report**: Generate initial findings from steps 5–6. Wait for both to complete before proceeding.
8. **Fact-Check** (Opus): Verify each finding from step 7 in the actual repo to ensure contextual correctness. Do not start until step 7 is complete.
9. **Cross-Repo Analysis** (Opus): If needed, check related repos in `../greybeard-data/sources/` for breaking changes (see below)
10. **Final Summary**: PASS/FAIL per lens with actionable details on failures

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

## Notes

- Lenses are designed to be quickly skimmable (all under 100 lines)
- Repos in `../greybeard-data/sources/` are not working environments—tests/console may not work
- **Always fetch before diffing**: `git fetch origin` ensures you have current refs
- **Use three-dot diff**: `git diff origin/main...HEAD` shows only branch changes; two-dot diff (`git diff origin/main`) includes unrelated changes merged to main and will produce misleading results
- **Pull related repos before cross-repo checks**: Stale local copies can cause false positives for breaking changes
