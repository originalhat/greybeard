# Run Record

`$GREYBEARD_DATA/output/improve/{repo}/runs/{run}/record.md`. Started in preflight, appended after every round by the parent, finished in `05-finish.md`. It is what a later conversation reads to learn what a run did, without the thread. PHI-free.

## Shape

```markdown
# Improve run {run} · {repo}

**Command:** {as typed}
**Branch:** {improve/YYYY-MM-DD-batch} · worktree: {path | none}
**Base:** origin/main @ {sha} → {final base sha after catch-up}
**Rounds:** {done} of {N | cap 20} · lines: {total} of {--loc target | no target} · stopped: {after N | reached --loc | 20-round cap | nothing left to build | human}
**Hotspots:** {date} · service {service} · top: {file (p95, hits)}, … | none ({why})

## Rounds

| Round | Candidate | Label | Kind | Commits | Review | Gate | Lines (branch total) | Status |
|-------|-----------|-------|------|---------|--------|------|----------------------|--------|
| 1 | I-{n} {title} | safe | test-only | {sha}..{sha} ({N}) | {tally} | pass | {round} ({total}) | done |

Steers given between rounds:
- before round {k}: {the steer and why}

## Validate
{report path} · {N} criteria, {pass}/{N} · bugs: {introduced} introduced ({fixed} fixed), {pre-existing} pre-existing | skipped: {why}

## Defects filed
| Ticket | Candidate | Priority | Needs validation |
|--------|-----------|----------|------------------|

## PR
{url · draft | local only}

## Decisions and open items
- {decisions taken on the human's behalf, questions, parked rounds}
```
