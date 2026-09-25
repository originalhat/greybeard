# Code Review Workflow

A multi-stage, multi-modal code review pipeline that evaluates changes against technical lenses and repo-specific context.

## Directory Structure

```
code-review/
├── AGENTS.md           # You are here
├── lenses/             # Generalized technical review criteria
├── context/            # Repo/team-specific review criteria
├── scripts/            # last-reviewed-sha.sh: is HEAD the SHA the last run record reviewed?
└── templates/          # Canonical output format, the run record, the calibration ledger
```

## Inputs

Triggered by **`review <github PR URL>`** (also accepts `review <branch-name> in <repo-name>` when there's no PR yet).

- A GitHub PR URL, or a branch to review (checked out under `$GREYBEARD_DATA/sources/{repo}/`). From a PR URL, resolve the repo and branch.
- The diff against `origin/main`

## Outputs

A single impact-first report: a pass/fail/nit tally, then numbered failures, then the nits, then any pre-existing findings. Each failure heading states the user-facing consequence; the body gives one sentence of context, then what goes wrong; a one-sentence **Fix** closes it. Nits print as one line each, numbered in the same run as the failures. A pre-existing finding — a defect already present and reachable on `origin/main` before this branch — gets the same one-line treatment, ranks last, and never counts as a failure or a nit. Written in Simplified Technical English at roughly a 10th grade reading level. Technical depth is held in context for follow-up, not printed.

**The format is defined in `templates/REPORT-FORMAT.md` and is not optional.** Read it before writing the report.

A run record at `$GREYBEARD_DATA/output/code-review/{repo}/runs/{date}-{pr{n} | branch}.md` per `templates/REVIEW-RUN-RECORD.md`: every finding the lenses raised, what steps 8 and 8b did with each one and why, the falsifiers, and the final tally. The report is for the author; the record is for whoever later asks why a finding was kept, demoted, or dropped.

`--calibrate` appends to a third artifact, `$GREYBEARD_DATA/output/code-review/{repo}/calibration.md` per `templates/CALIBRATION-RECORD.md`: one entry per merged PR comparing the human review threads with what the run records show the pipeline raised, and when.

## Modes

Plain `review` runs steps 1–11 below: the report, then the run record. `--fix` and `--interactive` change what happens after step 4 or after step 11; neither changes the evaluation itself. `--calibrate` runs no evaluation at all: it measures a finished review against the humans who reviewed the same PR.

### `--fix` (auto-fix)

If the invocation includes `--fix` (or "fix this branch", "auto-fix mode", "review and fix"): do steps 1–4 exactly as written, then **stop** and switch to `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/AGENTS.md`. That pipeline takes the diff from steps 1–4, classifies findings, auto-applies the safe ones, commits them separately from the branch's existing commits, and re-reviews (by re-running this pipeline without `--fix`, fresh) in a bounded loop. It never pushes.

`--fix` inherits plain `review`'s scope: the current branch only, never a PR URL for a branch you didn't check out yourself. `review-fix` commits to whatever branch it runs against, so to review someone else's work, leave `--fix` off.

### `--interactive` (draft-and-post)

If the invocation includes `--interactive` (or `—interactive` with an em dash, which macOS produces from a double hyphen; or "interactive review", "walk through findings", "draft comments one by one"): run steps 1–11 exactly as written, print the full report, then **stop and switch into a 1-by-1 draft-and-post loop** for each numbered failure. If no PR exists for the branch, say so before starting — there is nowhere to post.

If the report has a `## Data check`, walk the findings that do not depend on it first. Before you draft one that does, ask for the snippet output, then drop or re-rank on it.

For each failure, in order:

1. **Draft** a PR review comment in the user's voice (voice rules below). Do not post yet.
2. **Present the draft** under a short header naming the finding (e.g. `**#3 — Duplicate diagnosis warning**`), then close with one line: `Post, post as nit, revise, or skip?`
3. **Revise on feedback.** If the user rewrites or asks for tone changes, re-draft and re-present. `post as nit` (or `as micro-nit`) means prefix the body with `nit: ` (or `micro-nit: `) and post without re-presenting; record the downgrade in the run record. If they push back on whether the finding is real or in scope ("was this pre-existing?"), verify against `origin/main` and drop or reclassify rather than defending it.
4. **Post on approval** as an inline PR review comment, anchored at the `file:line` held from step 8, with the PR's head SHA as `commit_id`. Use the GitHub MCP review-comment tool and print the `html_url` from its response; when the response carries none, read it back with the MCP PR-comments tool (`pull_request_read`, review comments), not `gh`. `gh api repos/{owner}/{repo}/pulls/{n}/comments` is the fallback only when the MCP is not connected, and then as a standalone command: inside a `cd … &&`, a pipe, or `$(…)` it stays in the sandbox and fails.
5. **Move to the next** finding without waiting for a nudge.
6. **When every failure has been posted or skipped, offer one line:** `Say approve to submit an Approve review with a 👍 body, or done to stop.` On approve, submit an Approve review with body `👍` via the GitHub MCP review tool (fallback: `gh pr review {n} --approve --body "👍"`) and print the URL from its response, or read it back with the MCP reviews tool. Nothing else in the body unless the user gives their own text.
7. **When the author replies, test the reply before answering it.** Fetch the thread with the GitHub MCP PR-comments tool (fallback: `gh api repos/{owner}/{repo}/pulls/{n}/comments`) and read the `in_reply_to_id` chain. Author replies come in four shapes, and each has its own test:
   - *"That is pre-existing"* or *"that is out of scope."* Go find the recovery path or the prior behavior in the repo. If it is there, concede in one line and stop. Do not restate the conceded point in softer words.
   - *"The other thing is wrong, not this."* Work out which rule is authoritative, the same way step 8b does. If the author is right, the finding inverts rather than disappears: the inconsistency is real, it points at the code they named, and it becomes a follow-up instead of a change to this PR.
   - *"That is intentional."* Look for the comment, the doc, or the test that says so. Design intent that lives only in a PR reply is worth one question about where it is written down.

   - *"Good catch, will fix"* or a new commit that answers the thread. Review the fix before the thread counts as closed: diff only the commits pushed after the comment (`git diff {commented_sha}..{new_head}`, or the GitHub MCP `get_commit` when fetch fails), check them against the original finding and against the lenses the finding came from, and append the outcome to the record as `#N fixed in {sha}: holds` or `#N fixed in {sha}: {what is still wrong}`. A fix that lands after an approval is still unreviewed code; say so rather than letting the approval cover it.

   After conceding anything, re-read the findings still open. A conceded premise usually promotes one of them — if the author is right that the gate is wrong, then every path that skips that gate matters more than it did, not less.

Every post, user drop, reclassification, and concession in this loop is appended to the run record from step 11 under `## Interactive`, one line each with the finding number and the reason or `html_url`.

**Voice rules for interactive drafts** (do not restyle):

- One sentence by default: the thing the author should look at, ending in a question mark. Add a second sentence only when the consequence is not obvious from the first. Never three.
- Framed as a question where the finding admits one — `What happens if…`, `Is it intentional that…`, `Should…`. Lead with a question when the finding is about behavior the author may already have thought through.
- **Focus on the end-user impact**, not the implementation. What does the clinician / patient / operator experience? Skip the mechanism unless it's needed to make the question land.
- **Higher level, less programming plumbing.** Name the user-visible symptom before the code path. Don't restate the diff or narrate what the code does.
- **Do not talk about the fix.** No "consider adding X", no code snippets, no "we should refactor Y". Raise the question; let the author decide.
- Same simplified language as the report — no idioms, no "silently", no metaphors — with a looser sentence cap because it's a conversation.

- Nit drafts start with the literal prefix `nit: `.

**Skip pre-existing findings entirely** — they aren't this PR's to fix. **Nits come last, prefixed, and already drafted:** after the failures, name the one to three nits worth surfacing and present their drafts immediately, each starting with `nit: `, rather than waiting to be asked to show them. Post only the ones the user approves.

### `--calibrate <PR URL>` (post-merge calibration)

Run after a PR that had human review has merged, or once every reviewer has finished. It reviews nothing. It answers "what did the humans catch that the pipeline did not, and was it the same thing as last time".

1. **Fetch the human side.** Every review thread, review summary, and conversation comment on the PR (GitHub MCP PR tool: `get_review_comments`, `get_reviews`, `get_comments`), and the commit list with author timestamps (`get_commits`). Note which head SHA each review was submitted against.
2. **Fetch the pipeline side.** Every record for the branch or PR under `$GREYBEARD_DATA/output/code-review/{repo}/runs/` and `fix-runs/`. If there are none, say so in one line; the calibration still runs and every human thread is `never raised`.
3. **Build the timeline.** Pushes (commit timestamps) against review runs (record timestamps and SHAs). Every push whose HEAD has no record before the next human review is an **unreviewed push**; list it with what it added and how many lines.
4. **Classify every human thread** that asks for a change or questions behavior (skip approvals, thanks, and author replies). Find the matching finding in the records, then bucket it per `templates/CALIBRATION-RECORD.md`: `caught`, `found late`, `misjudged`, `never raised`, `not a miss`. For `misjudged` and `never raised`, name the lens or context file that should own it, or `none`.
5. **Append the entry** to `calibration.md` per the template. Create the file if it does not exist. PHI-free: paraphrase threads, no identifiers.
6. **Read the whole ledger, then propose.** Any lens, context file, or cause (`sequencing`, `judgment`) that appears as `never raised` or `misjudged` in two or more PRs becomes one proposal: the file to change and the one rule to add, in one sentence each. A reviewer who asks for the same shape on two or more PRs becomes a proposed entry in `context/REVIEWER-PRIORS.md`. Print the proposals under `## Proposals`. **Do not edit lenses or context files in this mode**; that is the human's call, or `retro`'s.
7. **Print** the entry and the proposals. Nothing else.

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
5. **Parallel Evaluation** (mid-tier model): Run each lens in `lenses/` against the diff (include PR context from step 4 and repo docs from step 4b if available). Lens agents may read the target repo's source directly — several lenses (`TRIGGER-COVERAGE`, `TESTING-COVERAGE`, `BULK-WRITE-SAFETY`) require reading the models and creation paths the diff touches, not just the diff. Steps 5 and 6 may run in parallel with each other. Launch every lens and context agent in **one message with `run_in_background: false`**: the turn does not end until all are back, and nothing is printed between hand-backs. Background agents re-invoke the parent at every completion, and each re-invocation becomes a "three agents left" line in the thread. Cross-repo checks (step 9) and repo-doc reads (step 4b) happen before the launch, not while waiting. One line at launch ("Running N lenses.") and the report are the only messages in this phase; review-fix re-reviews inherit this because they run this pipeline unchanged. Each lens agent returns, per finding: the **consequence** (what breaks, for whom), the mechanism in one or two sentences, `file:line`, and a suggested fix — plus whether it rises above a nit. Lens agents report raw; they do not format.

   **One agent per lens is the default.** Grouping lenses into fewer agents is allowed only under two conditions, both recorded in the run record's `Agents:` line: no group mixes an architecture lens (`SEPARATION-OF-CONCERNS`, `EXTENSIBILITY`, `CLARITY-SIMPLICITY`, `OBJECT-DESIGN`, `OPPORTUNISTIC-REFACTOR`) with a testing, domain, data, or security lens, because the design axis is the one that goes quiet when it shares an agent with defect hunting; and no group holds more than four lenses. Skipping a lens whose subject the diff cannot touch (React lenses on a backend-only branch) is fine; list the skipped lenses and the reason in the record's `Skipped lenses:` line.
6. **Context Evaluation** (mid-tier model): Run `context/` criteria against the diff (include PR context from step 4 and repo docs from step 4b if available). Evaluate the repo docs from step 4b as context files in their own right: an invariant stated in a domain `CLAUDE.md` that the diff violates is a finding, with the doc's path in place of a lens name.
7. **Report**: Aggregate findings from steps 5–6. Wait for both to complete before proceeding.
8. **Fact-Check** (frontier model): Verify each finding from step 7 in the actual repo to ensure contextual correctness. Do not start until step 7 is complete. Discard anything that doesn't hold up — an unconfirmed finding is dropped, not hedged. Also check the PR description's **premises** against the repo docs from step 4b and the models the diff touches: a claim like "brokers no-op naturally" or "X is the stale copy" that the code or a domain `CLAUDE.md` contradicts is itself a finding, ranked by the consequence of the code having been written on that premise. For each finding that survives, determine whether it's pre-existing: check whether its file:line falls inside a hunk this branch's diff actually touches (`git diff origin/main...HEAD -- {file}`); if it doesn't, confirm the branch didn't add a new caller, remove a guard, or otherwise make the defect newly reachable before marking it pre-existing. This determination happens once, centrally, here — not per-lens.

   **Pre-existing is decided per line, not per enclosing construct.** A new HTTP call inside an old lock, a new branch inside an old method, a new loop body inside an old loop, is this branch's. And **adding another instance of an existing pattern puts the pattern in scope**: the sixth method that takes credentials per call, the fourth file that copies the same timeout constants, is a finding that names the new instance and the ones it copied, not a pre-existing note.

   **A reverted review fix re-opens its finding.** List the branch's own `review-fix:` commits (`git log --format='%h %s' origin/main..HEAD --grep='^review-fix:'`). For each one, check whether a later commit on the branch removed or rewrote the lines it added (`git log -L` on its hunks, or `git blame HEAD` on those lines no longer pointing at it). If it did, take the finding that commit fixed, from its commit message and from the run record of that round, and check it again against HEAD as if a lens had just raised it. Reviewer feedback is the usual cause: the feedback is right about its own point, and the rewrite brings back the defect the earlier round removed. Record each re-opened finding in the run record with outcome `kept` or `dropped (8)`, citing the reverting commit. On origami_claims #9049 the round-1 fix for a stale `Individual.sex` was reverted while applying reviewer feedback, and the defect shipped.

   **Cost is a formula, not a phrase.** Any demotion, drop, or deferral that rests on cost or scale writes the cost as a function of a named N in the record's `Why` column (`N list calls + up to N² member reads per launch, N = children on the roster`), never as "one-time cost per item" or "small for typical inputs". If the formula is worse than linear in something a user controls, the finding is not a nit.
8b. **Falsify** (frontier model): Step 8 confirms a finding is internally consistent. This step tries to break it. For each surviving finding, write down the one fact that would make it false, then go look for that fact. Two failure modes recur and are worth naming:

   - **Escape hatch.** A finding that says a user is stuck, blocked, never prompted again, or has no way to recover is a claim about *every* path, not the one you read. Search for the recovery by the **state the user is in**, not by the field the finding named — a member with no patient record is found by `patient.nil?`, not by the consent timestamp. Cross the language boundary while you look: the backend sets a flag, and the React bundle that recovers from it often keys off something else entirely, in a different directory, with a different name. If any path lets the user out, the finding is a severity downgrade at most, and usually a drop.
   - **Assumed authority.** A finding of the form "this diverges from how X already works" is only as good as X. Confirm X is the rule that actually governs the capability, not the nearest predicate with a matching name. A dashboard flag and an eligibility service can disagree about who gets access, and when they do, the one the diff contradicts may be the wrong one. Read the comments around X before trusting it — a deliberate divergence is usually documented right there, in the file you are about to cite as the spec.
   - **Dead path.** A finding that reaches its users only through a legacy or secondary entry point (an old pricer, a self-service flow, a rarely used worker) is only as real as that entry point's traffic. Count production spans for the entry point over the Datadog retention window (`search_datadog_spans`, `env:production resource_name:*{Entry}*`) before keeping it. A scheduled poller that runs with no user traffic behind it does not count. Zero traffic is a drop; write the query and the count in the record's `Why` column. When Datadog is not connected, say so in the falsifier line instead of assuming the path is live. Repo docs and extracted knowledge describe what the code can do, not what production runs: on origami_claims #9099 both described Claros self-service pricing as current, and it had seen no traffic for a year.
   - **Data hunch.** Some falsifiers are facts about production data, not about code: how many rows are in the state the finding needs, whether any exist at all, which values a column actually holds. When neither the code nor Datadog can answer one, and the answer would drop the finding or change its rank, write a read-only Rails console snippet for the user to run. You run nothing.
     - Write one snippet per review round, with every data question batched into it.
     - Follow the snippet rules in `workflows/on-call/pipeline/01-triage.md` Phase 1d: strictly read-only, runnable as-is, and labeled `puts` output.
     - Make the snippet print its own scope (the environment, the time window, the base counts it queried), so a wrong assumption shows up in the output.
     - Return counts, booleans, and IDs only. Never names, DOBs, emails, or phone numbers.
     - Say which environment it targets (CP staging, CP prod, OC prod) and whether it must run inside docker.
     - The finding stays `kept`, with the falsifier line `pending console check`. The report prints the snippet under `## Data check`, and for each finding it decides, the result that keeps it and the result that drops it. When the output comes back, apply it the same as any other falsifier: drop, re-rank, and record the counts.
     - Do not write a snippet for a question the code or Datadog already answers.

     On origami_claims #9099, one snippet could have counted digital sales quote applications over the past year (that would have dropped the Claros margin finding) and counted the quotes whose actual enrollment is below the census (that would have sized the rate finding).

   A finding that fails falsification is dropped, not softened. Dropping one is not free: when a finding rested on a premise you just removed, re-rank everything that shared it before step 10. A finding ranked low because the main gate looked correct gets promoted the moment that gate turns out to be wrong.

9. **Cross-Repo Analysis** (frontier model): If needed, check related repos in `$GREYBEARD_DATA/sources/` for breaking changes (see below)
10. **Final Summary**: Write the report per `templates/REPORT-FORMAT.md`. Pre-existing findings go in their own section, ranked last, never counted as a failure or nit. Retain each finding's `file:line`, call path, and suggested fix in context to answer follow-ups — none of it goes in the report.
11. **Run Record**: Write `$GREYBEARD_DATA/output/code-review/{repo}/runs/{YYYY-MM-DD}-{pr{n} | branch}.md` per `templates/REVIEW-RUN-RECORD.md`. List every finding steps 5–6 raised, not only the survivors, each with its step 8 or 8b outcome (`kept`, `demoted to nit`, `promoted`, `dropped (8)`, `dropped (8b)`, `pre-existing`) and a one-line reason; the falsifier named for each surviving finding and whether it could be tested; any re-ranking from 8b; the cross-repo result; and the tally. PHI-free, one line per item. Create the `runs/` directory if it does not exist. This is the only durable record of the review; the report lives in the thread. **This step runs on every invocation of the pipeline**: a standalone `review`, each round inside `review-fix`, and the review inside `implement`. A fix-run record is the loop's log, not a substitute for the per-lens findings table; a round with no `runs/` file did not run this pipeline.

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

- **GitHub access: MCP first, `gh` as fallback.** Use the GitHub MCP tools (`mcp__GitHub__*`) for reading PRs, issues, files, reviews, and comments and for posting comments and reviews. They run inside Claude's process, so the Bash sandbox, its TLS proxy, and the keychain never get in the way. Fall back to the `gh` command only when the MCP is not connected yet (it starts through npx and can lag at session start). Listing or searching PRs (an author's open PRs, a stacked base, the PR for a branch) is `list_pull_requests` or `search_pull_requests`, not `gh pr list`. When `gh` does run, run it as a standalone command: the sandbox exclusion matches a whole simple command, so `cd … && gh …`, `gh … | head`, and `$(gh …)` stay sandboxed and fail on the network. Pushing local commits is always plain `git`; the MCP cannot push a branch.
- **Output format is fixed**: `templates/REPORT-FORMAT.md`. Impact in the heading, context then consequence in the body, one-sentence Fix, lens name in the footer. Number the failures, tally the passes, then list the nits one line each, then any pre-existing findings one line each. Never enumerate all lenses.
- **The run record is the audit trail.** A retro on a missed or wrongly dropped finding reads `$GREYBEARD_DATA/output/code-review/{repo}/runs/`, not the thread transcript. If a lens never raised the finding, that is a lens gap; if it was raised and dropped, the record's `Why` column says what step 8 or 8b believed. Write the record even when the tally is all passes.
- **`deferred` is not an outcome.** A finding is `kept`, `demoted to nit`, `promoted`, `dropped (8)`, `dropped (8b)`, or `pre-existing`. A real finding the author should decide on is `kept` and goes in the report (in `review-fix`, triage routes it `ask-user`). "Deferred" is how a quadratic fan-out was recorded as "one-time cost per child" on care_platform #980 and then blocked the PR in human review.
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
