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
2. **Diff**: Compare against `origin/main`
3. **Parallel Evaluation**: Run each lens in `lenses/` against the diff
4. **Context Evaluation**: Run `context/` criteria against the diff
5. **Report**: Generate initial findings
6. **Fact-Check**: Verify each issue in the repo to ensure contextual correctness
7. **Cross-Repo Analysis**: If needed, check related repos in `sources/` for clarity
8. **Final Summary**: PASS/FAIL per lens with actionable details on failures

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
- Always pull `origin/main` before comparing
