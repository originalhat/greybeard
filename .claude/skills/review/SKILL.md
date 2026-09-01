---
name: review
description: Run the Greybeard code-review pipeline against the current branch of the repository you're working in. Diffs the branch against origin/main, evaluates against all Greybeard lenses and repo-specific context, fact-checks findings, and runs cross-repo analysis against sibling repos in greybeard-data/sources. Use whenever the user wants a code review, PR review, lens check, or pre-merge review of their current branch — including phrases like "review this branch", "review my PR", "run the lenses", "code review", or "/review". Pass `--fix` (or phrasing like "fix this branch", "auto-fix mode", "review and fix") to additionally classify findings, auto-apply the safe ones, commit them, and loop re-reviews until clean — see the Auto-fix mode section below. Pass `--interactive` (or phrasing like "interactive review", "walk through findings", "draft comments one by one") to print the summary and then go 1-by-1 through each finding, drafting a PR review comment in the user's voice, revising on feedback, and posting to GitHub only after approval — see the Interactive mode section below. The skill works from any working directory; it operates on whatever git repo the user is currently in.
---

# Review

Runs the Greybeard code-review pipeline against the current branch of the current repository, with cross-repo analysis against sibling repos in the Greybeard data directory.

## Paths

These paths are hardcoded for this user's setup:

- **Greybeard repo** (lenses and context live here): `/Users/devin/workspace/greybeard`
- **Lenses directory**: `/Users/devin/workspace/greybeard/workflows/code-review/lenses/`
- **Context directory**: `/Users/devin/workspace/greybeard/workflows/code-review/context/`
- **Report format** (mandatory, read before writing the summary): `/Users/devin/workspace/greybeard/workflows/code-review/templates/REPORT-FORMAT.md`
- **Sibling repos for cross-repo analysis**: `/Users/devin/workspace/greybeard-data/sources/`
- **Auto-fix pipeline** (only used with `--fix`): `/Users/devin/workspace/greybeard/workflows/review-fix/CLAUDE.md`

If any of these paths are missing, stop and tell the user — do not silently skip.

## Auto-fix mode (`--fix`)

If this invocation includes `--fix` (or equivalent phrasing — "fix this branch", "auto-fix mode", "review and fix"): do steps 1–4 below exactly as written (confirm the repo, fetch latest, diff, optional PR context), then **stop** and switch to `/Users/devin/workspace/greybeard/workflows/review-fix/CLAUDE.md` instead of continuing to step 5. That pipeline takes the diff from steps 1–4, classifies findings, auto-applies the safe ones, commits them separately from the branch's existing commits, and re-reviews (by re-running this same skill without `--fix`, fresh) in a bounded loop until nothing auto-fixable remains. It never pushes.

Without `--fix`, ignore this section and follow steps 1–10 below as normal — this skill's behavior is unchanged from before `--fix` existed.

## Interactive mode (`--interactive`)

If this invocation includes `--interactive` (or equivalent phrasing — "interactive review", "walk through findings", "draft comments one by one"): run steps 1–10 below exactly as written, print the full report, then **stop and switch into a 1-by-1 draft-and-post loop** for each numbered failure. Do not draft comments for pre-existing findings — they aren't this PR's to fix. Nits are skipped by default; ask at the end whether any are worth calling out and only draft the ones the user names.

For each failure, in order:

1. **Draft** a PR review comment in the user's voice — see the voice rules below. Do not post yet.
2. **Present the draft** to the user under a short header naming the finding (e.g. `**#3 — Duplicate diagnosis warning**`).
3. **Revise on feedback.** If the user rewrites or asks for tone changes, re-draft and re-present. If they push back on whether the finding is real or in scope (e.g. "was this pre-existing?"), verify against `origin/main` and drop it or reclassify rather than defending it.
4. **Post on approval** as an inline PR review comment via `gh api repos/{owner}/{repo}/pulls/{n}/comments`. Anchor at the file:line held in working context from step 8. Use the PR's head SHA as `commit_id`. Print the returned `html_url` so the user can jump to it.
5. **Move to the next** finding without waiting for a nudge.

**Voice rules for interactive drafts** (this is what the user asked for; do not restyle):

- Concise. Two sentences is usually enough; three is the ceiling.
- Framed as a question where the finding admits one — `What happens if…`, `Is it intentional that…`, `Should…`. Not every finding needs to be a question, but lead with one when the finding is about behavior the author may have already thought through.
- **Focus on the end-user impact**, not the implementation. What does the clinician / patient / operator experience? Skip the mechanism unless it's needed to make the question land.
- **Higher level, less programming plumbing.** Name the user-visible symptom before the code path. Avoid restating the diff or narrating what the code does.
- **Do not talk about the fix.** No "consider adding X", no code snippets, no "we should refactor Y". The point is to raise the question and let the author decide.
- Same simplified language as the report — no idioms, no "silently", no metaphors — but the sentence-count cap is looser here because it's a conversation, not a summary.

**Skip pre-existing findings entirely.** Do not draft, do not present, do not ask. They already ranked last in the report; the interactive loop only covers what this PR introduced or newly exposed.

**Skip nits by default.** At the end of the failure loop, offer a short list of the nits with a one-line take on which (if any) are worth surfacing, and only draft the ones the user names.

If no PR exists for the branch, tell the user before starting — `--interactive` posts inline comments, and there's nowhere to post them without a PR.

Without `--interactive`, ignore this section — the skill prints the report and stops, as before.

## Inputs

- The current working directory must be inside a git repository. If `git rev-parse --show-toplevel` fails, tell the user and stop.
- The current branch (`git branch --show-current`). If the user is on `main` or `master`, ask whether they meant a different branch before continuing.
- The diff between the current branch and `origin/main` (three-dot).

## Execution

These steps are **strictly sequential** — do not start a step until prior steps are complete. The fact-check and cross-repo steps must wait for evaluation to finish.

### 1. Setup

- Confirm cwd is a git repo: `git rev-parse --show-toplevel`
- Capture the repo name from the basename of that path — this is used to identify siblings.
- Capture the current branch: `git branch --show-current`

### 2. Fetch latest

- `git fetch origin main`
- `git fetch origin {branch}` (skip gracefully if the branch isn't pushed)

### 3. Diff

- Use **three-dot diff**: `git diff origin/main...HEAD`
- Never use two-dot diff (`git diff origin/main`) — it includes unrelated changes merged to main after the branch was created and produces misleading results.

### 4. PR context (optional)

- If a PR exists for this branch, fetch its title, body, and linked issues: `gh pr view {branch} --json title,body,url`
- Feed this into lens and context evaluation as additional context.
- Skip gracefully if no PR exists.

### 5. Lens evaluation

- Read the lens index at `/Users/devin/workspace/greybeard/workflows/code-review/lenses/CLAUDE.md` to understand which lenses exist.
- If your harness supports spawning parallel subagents, spawn one per lens file in `lenses/` (excluding `CLAUDE.md`) to evaluate the diff against that lens, run them in parallel, and skip straight to step 7 once they all return. If it does not, evaluate the diff against each lens file yourself, one at a time.
- These subagents are a fan-out over many small, mechanical checks — use a fast, mid-tier model for them, not your strongest one. Concretely: Claude Sonnet in Claude Code (its default `reviewer`-style subagent tier); in Pi, the built-in `reviewer` role, optionally pinned to a fast/cheap model such as Kimi K2.7, Kimi K3 Fast, or GPT-OSS-120B via a per-role model override. The goal is breadth and speed, not maximum reasoning depth — that's reserved for step 8.
- Each lens evaluation returns PASS/FAIL. For every finding it must return four things: the **consequence** (what breaks, and for whom — a user, an operator, the data, or the next engineer), the mechanism in one or two sentences, `file:line`, and a suggested fix. It must also say whether the finding rises above a nit.
- Raw findings only at this stage — do not format, rank across lenses, or write prose for the user yet; that happens in step 10.

### 6. Context evaluation

- For each file in `/Users/devin/workspace/greybeard/workflows/code-review/context/` (excluding `CLAUDE.md`), evaluate the diff against that context document.
- If running lenses and context evaluation as separate subagents, steps 5 and 6 may run in parallel with each other. Otherwise, do them one after the other.

### 7. Initial report

- Aggregate findings from steps 5 and 6. Wait for both to finish before proceeding.

### 8. Fact-check

- For each finding, verify in the actual repo that the issue is real and contextually correct. Many lens hits are false positives once you read the surrounding code.
- Discard findings that don't hold up.
- For each finding that survives, determine whether it's pre-existing: check whether its file:line falls inside a hunk this branch's diff actually touches (`git diff origin/main...HEAD -- {file}`). If it doesn't, confirm the branch didn't add a new caller, remove a guard, or otherwise make the defect newly reachable — only then mark it pre-existing. Do this determination once, here, not per-lens.
- Do this yourself in the current session — don't delegate it to a subagent, even if your harness supports them. Fact-checking needs the full context this session already has, and it benefits from your strongest available model's judgment, not a fast/cheap one. Concretely: Claude Opus in Claude Code; in Pi/Fireworks, the frontier tier for the day — Kimi K3, DeepSeek V4 Pro, or GLM 5.2. If the main session isn't already running on that tier, that's a reason to start `review` on a stronger model rather than switch mid-skill.

### 9. Cross-repo analysis

- Identify whether the diff touches integration points: API endpoints, shared types, websocket messages, cron schedules, queue payloads, public functions in shared libraries.
- If yes, for each sibling repo under `/Users/devin/workspace/greybeard-data/sources/` (other than the current repo):
  - Pull latest main: `git -C /Users/devin/workspace/greybeard-data/sources/{other-repo} checkout main && git -C /Users/devin/workspace/greybeard-data/sources/{other-repo} pull`
  - Search for dependencies on the changed interfaces
  - Verify whether dependencies still match or have already been updated
- If the current repo isn't represented in greybeard-data, that's fine — the siblings are still useful for cross-repo dependency checks.

### 10. Final summary

**Read `/Users/devin/workspace/greybeard/workflows/code-review/templates/REPORT-FORMAT.md` and follow it exactly.** It is the canonical format; do not improvise one.

In short: a tally line (`✅ N passed  ❌ N failed  ⚠️ N nits  · N pre-existing`), then numbered failures ordered most-severe-first, then a `## ⚠️ Nits` list, then a `## Pre-Existing` list. Each failure **heading is the user-facing consequence in plain language**. The body gives one sentence of context — what this code does and when it runs — then what goes wrong for a person or for the data. Every failure ends with a one-sentence **`Fix:`** line: imperative, naming the actual change, no code. Lens name and file go in a single trailing `↳` footer line. Cross-repo breakage is folded in as a numbered failure; if clean, one line saying so.

**Print the nits.** They are cheap to fix and easy to miss, so they go in the report — but small. One line each: the change in imperative form, 15 words maximum, then the `↳` footer on the same line. No heading, no context sentence, no separate `Fix:` line — the line already is the fix. Number them in the same run as the failures (2 failures → the first nit is 3), so the reader can ask about any number. Order them by file. Cap the list at twelve; past that, print twelve and add `+{N} more nits — ask to see them.` Skip the heading entirely when there are no nits.

**Print the pre-existing findings, last.** A finding from step 8 marked pre-existing — the defect was already there and reachable on `origin/main` before this branch — goes under its own `## Pre-Existing` heading, after the nits, never counted in `❌ N failed` or `⚠️ N nits`. Same one-line shape as a nit (no `Fix:` line — nobody owes one on this PR), continuing the same number sequence, but state real severity in the sentence rather than letting the short line make it sound trivial. Skip the heading entirely when nothing was pre-existing.

Write it in **Simplified Technical English at about a 10th grade reading level**: 25 words maximum per sentence in bodies, 20 in the `Fix:` line, active voice, simple tenses, one term per concept, no vague quantities. Keep the articles (`The job skips the member`, not `Job skips member`). Cap noun clusters at three words. Do not use a verb as a noun — no `each submit`, `record the skip`. Prefer the positive form: `not enrolled`, not `un-enrolled`. **No idioms or metaphors** — "blast radius", "retry storm", "footgun", "silently", "happy path", "goes through" are all banned; say what actually happens. Technical nouns (`transaction`, `callback`, `N+1`) stay.

Before printing, reread each finding for the three habitual breaks: passive voice, a dropped article, a verb used as a noun.

Never enumerate the passing lenses. No `file:line`, code blocks, or before/after diffs in the report. Never write a nit or a pre-existing finding in the failure shape — no heading, no body paragraph, no `Fix:` line of its own. Never count a pre-existing finding toward `❌ N failed` or `⚠️ N nits` — it isn't this PR's to fix.

Hold every finding's `file:line`, call path, and suggested fix **in working context** so follow-ups ("what's the fix for 2?") are answerable immediately. Do not write a detail file to disk.

Close with one line offering depth on any number.

## Notes

- Lenses are designed to be quickly skimmable (all under 100 lines). Whoever evaluates a lens — a subagent or the main session — should read the full lens file before evaluating.
- Findings from `context/NITS.md` go in the nit list, not the failure list — unless one has a real consequence, in which case promote it to a numbered failure with a full body.
- Follow-ups are expected. When the user names a number, that's when `file:line`, the call path, and the concrete fix come out — not before.
- The current repo IS the one being reviewed. Sibling repos in `greybeard-data/sources/` are read-only references for cross-repo analysis — do not modify them beyond `git pull` on main.
- If the user's cwd repo is also present under `greybeard-data/sources/`, prefer the cwd checkout as the source of truth for the diff. The greybeard-data copy may be stale.
- Always fetch before diffing. Stale refs produce misleading diffs.
- `--fix` inherits this skill's existing scope: the current branch only, never a PR URL for a branch you didn't check out yourself. `review-fix` commits to whatever branch it runs against, so if you want to review someone else's work, leave `--fix` off.
