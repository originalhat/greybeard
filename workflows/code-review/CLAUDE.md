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

- A GitHub PR URL, or a branch to review (checked out under `$GREYBEARD_DATA/sources/{repo}/`). From a PR URL, resolve the repo and branch.
- The diff against `origin/main`

## Outputs

A single impact-first report: a pass/fail/nit tally, then numbered failures, then the nits, then any pre-existing findings. Each failure heading states the user-facing consequence; the body gives one sentence of context, then what goes wrong; a one-sentence **Fix** closes it. Nits print as one line each, numbered in the same run as the failures. A pre-existing finding — a defect already present and reachable on `origin/main` before this branch — gets the same one-line treatment, ranks last, and never counts as a failure or a nit. Written in Simplified Technical English at roughly a 10th grade reading level. Technical depth is held in context for follow-up, not printed.

**The format is defined in `templates/REPORT-FORMAT.md` and is not optional.** Read it before writing the report.

## Modes

Plain `review` runs steps 1–10 below and stops at the report. Two flags change what happens after step 4 or after step 10; neither changes the evaluation itself.

### `--fix` (auto-fix)

If the invocation includes `--fix` (or "fix this branch", "auto-fix mode", "review and fix"): do steps 1–4 exactly as written, then **stop** and switch to `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md`. That pipeline takes the diff from steps 1–4, classifies findings, auto-applies the safe ones, commits them separately from the branch's existing commits, and re-reviews (by re-running this pipeline without `--fix`, fresh) in a bounded loop. It never pushes.

`--fix` inherits plain `review`'s scope: the current branch only, never a PR URL for a branch you didn't check out yourself. `review-fix` commits to whatever branch it runs against, so to review someone else's work, leave `--fix` off.

### `--interactive` (draft-and-post)

If the invocation includes `--interactive` (or "interactive review", "walk through findings", "draft comments one by one"): run steps 1–10 exactly as written, print the full report, then **stop and switch into a 1-by-1 draft-and-post loop** for each numbered failure. If no PR exists for the branch, say so before starting — there is nowhere to post.

For each failure, in order:

1. **Draft** a PR review comment in the user's voice (voice rules below). Do not post yet.
2. **Present the draft** under a short header naming the finding (e.g. `**#3 — Duplicate diagnosis warning**`).
3. **Revise on feedback.** If the user rewrites or asks for tone changes, re-draft and re-present. If they push back on whether the finding is real or in scope ("was this pre-existing?"), verify against `origin/main` and drop or reclassify rather than defending it.
4. **Post on approval** as an inline PR review comment via `gh api repos/{owner}/{repo}/pulls/{n}/comments`, anchored at the `file:line` held from step 8, with the PR's head SHA as `commit_id`. Print the returned `html_url`.
5. **Move to the next** finding without waiting for a nudge.

**Voice rules for interactive drafts** (do not restyle):

- Concise. Two sentences is usually enough; three is the ceiling.
- Framed as a question where the finding admits one — `What happens if…`, `Is it intentional that…`, `Should…`. Lead with a question when the finding is about behavior the author may already have thought through.
- **Focus on the end-user impact**, not the implementation. What does the clinician / patient / operator experience? Skip the mechanism unless it's needed to make the question land.
- **Higher level, less programming plumbing.** Name the user-visible symptom before the code path. Don't restate the diff or narrate what the code does.
- **Do not talk about the fix.** No "consider adding X", no code snippets, no "we should refactor Y". Raise the question; let the author decide.
- Same simplified language as the report — no idioms, no "silently", no metaphors — with a looser sentence cap because it's a conversation.

**Skip pre-existing findings entirely** — they aren't this PR's to fix. **Skip nits by default**; at the end, offer a one-line take on which nits (if any) are worth surfacing and draft only the ones the user names.

## Execution

### Model Tiers

- **Steps 5–6 (Evaluation):** Fast, economical mid-tier model (currently Sonnet) — pattern matching against lenses and context, fast and parallelizable
- **Steps 8–9 (Fact-Check, Cross-Repo):** Most capable available frontier model — requires judgment, cross-referencing, and contextual reasoning

### Steps

These steps are **strictly sequential** — do not start a step until all prior steps are complete.

1. **Setup**: Check out the branch under `$GREYBEARD_DATA/sources/{repo}/`
2. **Fetch Latest**: Run `git fetch origin main` and `git fetch origin {branch}` to ensure refs are current
3. **Diff**: Use three-dot diff (`git diff origin/main...HEAD`) to see only branch changes, excluding unrelated changes merged to main after the branch was created
4. **PR Context** (optional): If a PR exists for the branch, fetch its title, description, and linked issues (`gh pr view {branch} --json title,body,url` or the GitHub MCP tools). Feed this as additional context to lens and context evaluation. Skip gracefully if no PR exists.
5. **Parallel Evaluation** (mid-tier model): Run each lens in `lenses/` against the diff (include PR context from step 4 if available). Steps 5 and 6 may run in parallel with each other. Each lens agent returns, per finding: the **consequence** (what breaks, for whom), the mechanism in one or two sentences, `file:line`, and a suggested fix — plus whether it rises above a nit. Lens agents report raw; they do not format.
6. **Context Evaluation** (mid-tier model): Run `context/` criteria against the diff (include PR context from step 4 if available)
7. **Report**: Aggregate findings from steps 5–6. Wait for both to complete before proceeding.
8. **Fact-Check** (frontier model): Verify each finding from step 7 in the actual repo to ensure contextual correctness. Do not start until step 7 is complete. Discard anything that doesn't hold up — an unconfirmed finding is dropped, not hedged. For each finding that survives, determine whether it's pre-existing: check whether its file:line falls inside a hunk this branch's diff actually touches (`git diff origin/main...HEAD -- {file}`); if it doesn't, confirm the branch didn't add a new caller, remove a guard, or otherwise make the defect newly reachable before marking it pre-existing. This determination happens once, centrally, here — not per-lens.
9. **Cross-Repo Analysis** (frontier model): If needed, check related repos in `$GREYBEARD_DATA/sources/` for breaking changes (see below)
10. **Final Summary**: Write the report per `templates/REPORT-FORMAT.md`. Pre-existing findings go in their own section, ranked last, never counted as a failure or nit. Retain each finding's `file:line`, call path, and suggested fix in context to answer follow-ups — none of it goes in the report.

### Cross-Repo Analysis

Before comparing against other repos in `$GREYBEARD_DATA/sources/`:

1. **Pull latest main** for each related repo: `git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{other-repo}" checkout main && git -C "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/{other-repo}" pull`
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

- **Output format is fixed**: `templates/REPORT-FORMAT.md`. Impact in the heading, context then consequence in the body, one-sentence Fix, lens name in the footer. Number the failures, tally the passes, then list the nits one line each, then any pre-existing findings one line each. Never enumerate all lenses.
- **Pre-existing findings are determined in fact-check, not per-lens**: a finding is pre-existing if its file:line isn't part of this branch's diff and the branch didn't newly expose or make it reachable. It's real, but it isn't this PR's to fix, so it ranks last and is never counted as a failure or nit.
- **No metaphors in findings.** No "blast radius", "retry storm", "footgun". Say what happens. Short active sentences, one term per concept.
- Lenses are designed to be quickly skimmable (all under 100 lines)
- Repos in `$GREYBEARD_DATA/sources/` are not working environments—tests/console may not work
- **Always fetch before diffing**: `git fetch origin` ensures you have current refs
- **Use three-dot diff**: `git diff origin/main...HEAD` shows only branch changes; two-dot diff (`git diff origin/main`) includes unrelated changes merged to main and will produce misleading results
- **Pull related repos before cross-repo checks**: Stale local copies can cause false positives for breaking changes
- **Prefer the user's own checkout when it exists.** If the branch under review is checked out in the user's cwd as well as under `$GREYBEARD_DATA/sources/`, diff the cwd copy — the data-directory clone may be stale.
- **Follow-ups are expected.** Hold every finding's `file:line`, call path, and suggested fix in working context; print them only when the user names a number.
- **`context/NITS.md` findings go in the nit list**, not the failure list — unless one has a real consequence, in which case promote it to a numbered failure with a full body.
