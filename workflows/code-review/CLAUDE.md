# Code Review Workflow

A multi-stage, multi-modal code review pipeline that evaluates changes against technical lenses and repo-specific context.

## Directory Structure

```
code-review/
├── CLAUDE.md           # You are here
├── lenses/             # Generalized technical review criteria
├── context/            # Repo/team-specific review criteria
└── templates/          # Canonical output format and the run record
```

## Inputs

Triggered by **`review <github PR URL>`** (also accepts `review <branch-name> in <repo-name>` when there's no PR yet).

- A GitHub PR URL, or a branch to review (checked out under `$GREYBEARD_DATA/sources/{repo}/`). From a PR URL, resolve the repo and branch.
- The diff against `origin/main`

## Outputs

A single impact-first report: a pass/fail/nit tally, then numbered failures, then the nits, then any pre-existing findings. Each failure heading states the user-facing consequence; the body gives one sentence of context, then what goes wrong; a one-sentence **Fix** closes it. Nits print as one line each, numbered in the same run as the failures. A pre-existing finding — a defect already present and reachable on `origin/main` before this branch — gets the same one-line treatment, ranks last, and never counts as a failure or a nit. Written in Simplified Technical English at roughly a 10th grade reading level. Technical depth is held in context for follow-up, not printed.

**The format is defined in `templates/REPORT-FORMAT.md` and is not optional.** Read it before writing the report.

A run record at `$GREYBEARD_DATA/output/code-review/{repo}/runs/{date}-{pr{n} | branch}.md` per `templates/REVIEW-RUN-RECORD.md`: every finding the lenses raised, what steps 8 and 8b did with each one and why, the falsifiers, and the final tally. The report is for the author; the record is for whoever later asks why a finding was kept, demoted, or dropped.

## Modes

Plain `review` runs steps 1–11 below: the report, then the run record. Two flags change what happens after step 4 or after step 11; neither changes the evaluation itself.

### `--fix` (auto-fix)

If the invocation includes `--fix` (or "fix this branch", "auto-fix mode", "review and fix"): do steps 1–4 exactly as written, then **stop** and switch to `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md`. That pipeline takes the diff from steps 1–4, classifies findings, auto-applies the safe ones, commits them separately from the branch's existing commits, and re-reviews (by re-running this pipeline without `--fix`, fresh) in a bounded loop. It never pushes.

`--fix` inherits plain `review`'s scope: the current branch only, never a PR URL for a branch you didn't check out yourself. `review-fix` commits to whatever branch it runs against, so to review someone else's work, leave `--fix` off.

### `--interactive` (draft-and-post)

If the invocation includes `--interactive` (or `—interactive` with an em dash, which macOS produces from a double hyphen; or "interactive review", "walk through findings", "draft comments one by one"): run steps 1–11 exactly as written, print the full report, then **stop and switch into a 1-by-1 draft-and-post loop** for each numbered failure. If no PR exists for the branch, say so before starting — there is nowhere to post.

For each failure, in order:

1. **Draft** a PR review comment in the user's voice (voice rules below). Do not post yet.
2. **Present the draft** under a short header naming the finding (e.g. `**#3 — Duplicate diagnosis warning**`).
3. **Revise on feedback.** If the user rewrites or asks for tone changes, re-draft and re-present. If they push back on whether the finding is real or in scope ("was this pre-existing?"), verify against `origin/main` and drop or reclassify rather than defending it.
4. **Post on approval** as an inline PR review comment, anchored at the `file:line` held from step 8, with the PR's head SHA as `commit_id`. Use the GitHub MCP review-comment tool; fall back to `gh api repos/{owner}/{repo}/pulls/{n}/comments` if the MCP is not connected. Print the returned `html_url`.
5. **Move to the next** finding without waiting for a nudge.
6. **When every failure has been posted or skipped, offer one line:** `Say approve to submit an Approve review with a 👍 body, or done to stop.` On approve, submit an Approve review with body `👍` via the GitHub MCP review tool (fallback: `gh pr review {n} --approve --body "👍"`) and print the URL. Nothing else in the body.
7. **When the author replies, test the reply before answering it.** Fetch the thread with the GitHub MCP PR-comments tool (fallback: `gh api repos/{owner}/{repo}/pulls/{n}/comments`) and read the `in_reply_to_id` chain. Author pushback comes in three shapes, and each has its own test:
   - *"That is pre-existing"* or *"that is out of scope."* Go find the recovery path or the prior behavior in the repo. If it is there, concede in one line and stop. Do not restate the conceded point in softer words.
   - *"The other thing is wrong, not this."* Work out which rule is authoritative, the same way step 8b does. If the author is right, the finding inverts rather than disappears: the inconsistency is real, it points at the code they named, and it becomes a follow-up instead of a change to this PR.
   - *"That is intentional."* Look for the comment, the doc, or the test that says so. Design intent that lives only in a PR reply is worth one question about where it is written down.

   After conceding anything, re-read the findings still open. A conceded premise usually promotes one of them — if the author is right that the gate is wrong, then every path that skips that gate matters more than it did, not less.

Every post, user drop, reclassification, and concession in this loop is appended to the run record from step 11 under `## Interactive`, one line each with the finding number and the reason or `html_url`.

**Voice rules for interactive drafts** (do not restyle):

- Concise. Two sentences is usually enough; three is the ceiling.
- Framed as a question where the finding admits one — `What happens if…`, `Is it intentional that…`, `Should…`. Lead with a question when the finding is about behavior the author may already have thought through.
- **Focus on the end-user impact**, not the implementation. What does the clinician / patient / operator experience? Skip the mechanism unless it's needed to make the question land.
- **Higher level, less programming plumbing.** Name the user-visible symptom before the code path. Don't restate the diff or narrate what the code does.
- **Do not talk about the fix.** No "consider adding X", no code snippets, no "we should refactor Y". Raise the question; let the author decide.
- Same simplified language as the report — no idioms, no "silently", no metaphors — with a looser sentence cap because it's a conversation.

- Nit drafts start with the literal prefix `nit: `.

**Skip pre-existing findings entirely** — they aren't this PR's to fix. **Nits come last, prefixed, and already drafted:** after the failures, name the one to three nits worth surfacing and present their drafts immediately, each starting with `nit: `, rather than waiting to be asked to show them. Post only the ones the user approves.

## Execution

### Model Tiers

- **Steps 5–6 (Evaluation):** Fast, economical mid-tier model (currently Sonnet) — pattern matching against lenses and context, fast and parallelizable
- **Steps 8, 8b, 9 (Fact-Check, Falsify, Cross-Repo):** Most capable available frontier model — requires judgment, cross-referencing, and contextual reasoning

### Steps

These steps are **strictly sequential** — do not start a step until all prior steps are complete.

1. **Setup**: Check out the branch under `$GREYBEARD_DATA/sources/{repo}/`
2. **Fetch Latest**: Run `git fetch origin main` and `git fetch origin {branch}` to ensure refs are current
3. **Diff**: Use three-dot diff (`git diff origin/main...HEAD`) to see only branch changes, excluding unrelated changes merged to main after the branch was created
4. **PR Context** (optional): If a PR exists for the branch, fetch its title, description, and linked issues with the GitHub MCP PR tool (fallback: `gh pr view {branch} --json title,body,url`). Feed this as additional context to lens and context evaluation. Skip gracefully if no PR exists. Treat the description as the author's **claims**, not as facts — step 8 checks them.
4b. **Repo Docs**: Read the target repo's own agent docs and pass them to every lens and context agent alongside `context/`: the root `CLAUDE.md` / `AGENTS.md`, plus any `CLAUDE.md` or `README.md` in a directory the diff touches or in any ancestor of one (for `domains/sana_care/workers/foo.rb`, that's `domains/sana_care/CLAUDE.md` and `domains/CLAUDE.md`). These carry the invariants the repo's own engineers wrote down — what a model represents, which record is canonical, which populations exist — and they are the cheapest domain knowledge available; they stand in for the `DOMAIN-KNOWLEDGE` lens when no extracted knowledge exists. Skip gracefully when none exist, but say so in one line so the silence is visible.
5. **Parallel Evaluation** (mid-tier model): Run each lens in `lenses/` against the diff (include PR context from step 4 and repo docs from step 4b if available). Lens agents may read the target repo's source directly — several lenses (`TRIGGER-COVERAGE`, `TESTING-COVERAGE`, `BULK-WRITE-SAFETY`) require reading the models and creation paths the diff touches, not just the diff. Steps 5 and 6 may run in parallel with each other. Each lens agent returns, per finding: the **consequence** (what breaks, for whom), the mechanism in one or two sentences, `file:line`, and a suggested fix — plus whether it rises above a nit. Lens agents report raw; they do not format.
6. **Context Evaluation** (mid-tier model): Run `context/` criteria against the diff (include PR context from step 4 and repo docs from step 4b if available). Evaluate the repo docs from step 4b as context files in their own right: an invariant stated in a domain `CLAUDE.md` that the diff violates is a finding, with the doc's path in place of a lens name.
7. **Report**: Aggregate findings from steps 5–6. Wait for both to complete before proceeding.
8. **Fact-Check** (frontier model): Verify each finding from step 7 in the actual repo to ensure contextual correctness. Do not start until step 7 is complete. Discard anything that doesn't hold up — an unconfirmed finding is dropped, not hedged. Also check the PR description's **premises** against the repo docs from step 4b and the models the diff touches: a claim like "brokers no-op naturally" or "X is the stale copy" that the code or a domain `CLAUDE.md` contradicts is itself a finding, ranked by the consequence of the code having been written on that premise. For each finding that survives, determine whether it's pre-existing: check whether its file:line falls inside a hunk this branch's diff actually touches (`git diff origin/main...HEAD -- {file}`); if it doesn't, confirm the branch didn't add a new caller, remove a guard, or otherwise make the defect newly reachable before marking it pre-existing. This determination happens once, centrally, here — not per-lens.
8b. **Falsify** (frontier model): Step 8 confirms a finding is internally consistent. This step tries to break it. For each surviving finding, write down the one fact that would make it false, then go look for that fact. Two failure modes recur and are worth naming:

   - **Escape hatch.** A finding that says a user is stuck, blocked, never prompted again, or has no way to recover is a claim about *every* path, not the one you read. Search for the recovery by the **state the user is in**, not by the field the finding named — a member with no patient record is found by `patient.nil?`, not by the consent timestamp. Cross the language boundary while you look: the backend sets a flag, and the React bundle that recovers from it often keys off something else entirely, in a different directory, with a different name. If any path lets the user out, the finding is a severity downgrade at most, and usually a drop.
   - **Assumed authority.** A finding of the form "this diverges from how X already works" is only as good as X. Confirm X is the rule that actually governs the capability, not the nearest predicate with a matching name. A dashboard flag and an eligibility service can disagree about who gets access, and when they do, the one the diff contradicts may be the wrong one. Read the comments around X before trusting it — a deliberate divergence is usually documented right there, in the file you are about to cite as the spec.

   A finding that fails falsification is dropped, not softened. Dropping one is not free: when a finding rested on a premise you just removed, re-rank everything that shared it before step 10. A finding ranked low because the main gate looked correct gets promoted the moment that gate turns out to be wrong.

9. **Cross-Repo Analysis** (frontier model): If needed, check related repos in `$GREYBEARD_DATA/sources/` for breaking changes (see below)
10. **Final Summary**: Write the report per `templates/REPORT-FORMAT.md`. Pre-existing findings go in their own section, ranked last, never counted as a failure or nit. Retain each finding's `file:line`, call path, and suggested fix in context to answer follow-ups — none of it goes in the report.
11. **Run Record**: Write `$GREYBEARD_DATA/output/code-review/{repo}/runs/{YYYY-MM-DD}-{pr{n} | branch}.md` per `templates/REVIEW-RUN-RECORD.md`. List every finding steps 5–6 raised, not only the survivors, each with its step 8 or 8b outcome (`kept`, `demoted to nit`, `promoted`, `dropped (8)`, `dropped (8b)`, `pre-existing`) and a one-line reason; the falsifier named for each surviving finding and whether it could be tested; any re-ranking from 8b; the cross-repo result; and the tally. PHI-free, one line per item. Create the `runs/` directory if it does not exist. This is the only durable record of the review; the report lives in the thread.

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

- **GitHub access: MCP first, `gh` as fallback.** Use the GitHub MCP tools (`mcp__GitHub__*`) for reading PRs, issues, files, reviews, and comments and for posting comments and reviews. They run inside Claude's process, so the Bash sandbox, its TLS proxy, and the keychain never get in the way. Fall back to the `gh` command only when the MCP is not connected yet (it starts through npx and can lag at session start); `gh` is excluded from the sandbox, so it works without a retry. Pushing local commits is always plain `git`; the MCP cannot push a branch.
- **Output format is fixed**: `templates/REPORT-FORMAT.md`. Impact in the heading, context then consequence in the body, one-sentence Fix, lens name in the footer. Number the failures, tally the passes, then list the nits one line each, then any pre-existing findings one line each. Never enumerate all lenses.
- **The run record is the audit trail.** A retro on a missed or wrongly dropped finding reads `$GREYBEARD_DATA/output/code-review/{repo}/runs/`, not the thread transcript. If a lens never raised the finding, that is a lens gap; if it was raised and dropped, the record's `Why` column says what step 8 or 8b believed. Write the record even when the tally is all passes.
- **Fact-check confirms; step 8b tries to falsify.** These are different jobs and the second one is the one that gets skipped. Confirming a mechanism is easy and feels like verification. The finding still dies if some other path recovers the user, or if the behavior it calls a divergence is the correct one. Name the falsifier, go look for it, and drop what fails.
- **Pre-existing findings are determined in fact-check, not per-lens**: a finding is pre-existing if its file:line isn't part of this branch's diff and the branch didn't newly expose or make it reachable. It's real, but it isn't this PR's to fix, so it ranks last and is never counted as a failure or nit.
- **No metaphors in findings.** No "blast radius", "retry storm", "footgun". Say what happens. Short active sentences, one term per concept.
- Lenses are designed to be quickly skimmable (all under 100 lines)
- Repos in `$GREYBEARD_DATA/sources/` are not working environments—tests/console may not work
- **Always fetch before diffing**: `git fetch origin` ensures you have current refs
- **Read the target repo's own docs**: root `CLAUDE.md`/`AGENTS.md` and any `CLAUDE.md`/`README.md` on the path to a touched file go to every lens and context agent. A repo's domain docs are extracted knowledge the repo already wrote; do not review without them.
- **Use three-dot diff**: `git diff origin/main...HEAD` shows only branch changes; two-dot diff (`git diff origin/main`) includes unrelated changes merged to main and will produce misleading results
- **Pull related repos before cross-repo checks**: Stale local copies can cause false positives for breaking changes
- **Prefer the user's own checkout when it exists.** If the branch under review is checked out in the user's cwd as well as under `$GREYBEARD_DATA/sources/`, diff the cwd copy — the data-directory clone may be stale.
- **Follow-ups are expected.** Hold every finding's `file:line`, call path, and suggested fix in working context; print them only when the user names a number.
- **`context/NITS.md` findings go in the nit list**, not the failure list — unless one has a real consequence, in which case promote it to a numbered failure with a full body.
