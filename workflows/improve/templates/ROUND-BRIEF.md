# Round Brief

`$GREYBEARD_DATA/output/improve/{repo}/runs/{run}/brief.md`. The parent writes it in preflight and updates it before every round. Each round's subagent gets its path as the prompt's first line, and returns the report at the bottom. It is how the parent's view of the whole run reaches each round, without each round re-learning what earlier rounds learned.

## Brief

```markdown
# Improve run {run} · {repo}

## This round
- Round: {k} of {N} | {k}, until {--loc target} lines ({total} so far)
- Mode: {improve | improve I-n | discover}
- Candidate: {I-n, for `improve I-n` | pick per 04-build}
- Round base: {sha}  (the batch branch's HEAD when this round starts)
- Steer: {e.g. "rounds 2-3 were test-only; prefer an app-code candidate" | none}
- Focus: {path | perf (hotspot anchors and perf candidates only) | none}

## Where
- Workflow: run `${CLAUDE_PLUGIN_ROOT}/workflows/improve/pipeline/01-slice.md` through `04-build.md` (with --focus {path} | for I-n: 04-build.md only)
- Repo: {repo} · checkout: {path} · branch: {improve/YYYY-MM-DD-batch} (already checked out; don't create, switch, or push branches)
- Knowledge base: $GREYBEARD_DATA/output/improve/{repo}/
- Stack: {none needed | slot {n}, app URL {url} | start one per implement only if this round needs the browser}

## Rules for every round
- One candidate. Its commits go on this branch; implement runs with --no-validate, and its review is `review --since {round base}`.
- Don't take or remove the knowledge base lock; the parent holds it.
- Don't push, open a PR, file a ticket, or post anywhere. Defects go in the report.
- Don't ask the human anything. Decisions and questions go in the report.
- Don't touch other worktrees or stacks on this machine.

## Branch so far
| Round | Candidate | Kind | Files |
|-------|-----------|------|-------|
| 1 | I-20 | test-only | spec/models/referrals/referral_spec.rb |
Files changed by earlier rounds: read them at HEAD, not at origin/main.

## Lessons
- {setup: "a new worktree needs `yarn install` in client/ once", "commits in a worktree need the sandbox off"}
- {knowledge: "Sidekiq.transactional_push! is global; enqueues inside a transaction are not defects"}
- {settled: "I-42 is waiting on a product answer; don't re-raise it"}
```

## Round report

The subagent's final message, exactly this shape:

```markdown
ROUND {k} REPORT
- Status: done | parked ({why}; commits on improve-parked/{id}) | nothing to build ({closest candidate and what it lacks})
- Slice: {anchor} + {with} | none ({why}) | skipped (explicit I-n)
- Knowledge: +{N} candidates ({safe}/{flagged}/{out}), {N} dropped, patterns at threshold: {name → I-n | none}, conventions: +{N}
- Built: I-{n} [{safe | flagged}] {title}
- Kind: test-only | app-code
- Commits: {sha} {subject}; …
- Review: {run record path} · {tally} · {N} fixed by review-fix
- Gate: pass ({files} files, {lines} lines) | fail ({reasons})
- Proof: {how the new or changed tests were shown to fail when the behavior breaks}
- Perf: {measure: before → after, for a perf round | none}
- Behavior to validate: {flows a user goes through that touch the changed code; unchanged | flagged: userVisible} | none
- Defects noticed: I-{n} {title} ({confidence}); …
- Decisions: {what the round decided on the human's behalf}
- Questions: {for the human, or none}
- Lessons: {anything the next round should know: setup, tooling, conventions}
```
