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

- A branch to review (checked out under `sources/{repo}/`)
- The diff against `origin/main`

## Outputs

- A concise summary with PASS/FAIL per lens
- Issue descriptions with location and potential fix for any failures

## Execution

1. **Setup**: Check out the branch under `sources/{repo}/`
2. **Fetch Latest**: Run `git fetch origin main` and `git fetch origin {branch}` to ensure refs are current
3. **Diff**: Use three-dot diff (`git diff origin/main...HEAD`) to see only branch changes, excluding unrelated changes merged to main after the branch was created
4. **Parallel Evaluation**: Run each lens in `lenses/` against the diff
5. **Context Evaluation**: Run `context/` criteria against the diff
6. **Report**: Generate initial findings
7. **Fact-Check**: Verify each issue in the repo to ensure contextual correctness
8. **Cross-Repo Analysis**: If needed, check related repos in `sources/` for breaking changes (see below)
9. **Final Summary**: PASS/FAIL per lens with actionable details on failures

### Cross-Repo Analysis

Before comparing against other repos in `sources/`:

1. **Pull latest main** for each related repo: `git -C sources/{other-repo} checkout main && git -C sources/{other-repo} pull`
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
- Repos in `sources/` are not working environments—tests/console may not work
- **Always fetch before diffing**: `git fetch origin` ensures you have current refs
- **Use three-dot diff**: `git diff origin/main...HEAD` shows only branch changes; two-dot diff (`git diff origin/main`) includes unrelated changes merged to main and will produce misleading results
- **Pull related repos before cross-repo checks**: Stale local copies can cause false positives for breaking changes
