# Validation Run Record Format

Written to `$GREYBEARD_DATA/output/validate/{repo}/{YYYY-MM-DD}-{pr{n} | branch}/record.md`, next to `report.md` and `screens/`. One directory per run, never appended to. A second run on the same branch the same day adds a `-2` suffix. The sequence of runs is itself the record of a branch converging.

The report is for the author. The record is for whoever later asks "did we test that?" or tunes the loop. PHI-free: local test data only, no real member identifiers.

## Shape

```markdown
# Validate run · {repo} · {pr{n} | branch} · {YYYY-MM-DD}

- **SHA:** {sha}
- **Intent source:** {ticket ID | PR description | freeform}
- **Interfaces:** {browser at {url} | API at {url} | console | …}
- **Mode:** {check + explore | check only}
- **Rounds:** {N} of {cap} · **Stopped because:** {backlog empty | saturated | cap reached | blocking finding}

## Change map

- **Surfaces:** {where users or callers meet the change, and the interface for each}
- **Entities:** {things created, read, updated, or deleted, and their relationships}
- **States:** {statuses or modes and the events between them; the unfilled cells that became charters}
- **Data paths:** {everywhere the data shows up, and how each was found}
- **Ecosystem:** {dependencies and trust boundaries}
- **Never and Always:** {one line per rule}
- **Nightmare headline:** {the headline, and the causes that became charters}

## Check

| # | Criterion | Result | Note |
|---|-----------|--------|------|
| 1 | {criterion} | pass / fail / couldn't verify | {one line} |

## Rounds

### Round {n}

| Charter | Resources | Coverage |
|---------|-----------|----------|
| {target → information} | {lens, persona, data, role, tool} | {what was tried, one line} |

- **Findings:** {#ids raised this round}
- **Leads:** {each lead, and what the debrief did with it: chartered as C{n}, or dropped (outside the change map)}
- **Backlog after debrief:** {charter ids, in order}

## Findings

| # | Finding | Round | Lens | Oracle | Confirm | Scope | Severity |
|---|---------|-------|------|--------|---------|-------|----------|
| 4 | {one line} | {n} | {LENS} | {oracle} | confirmed / couldn't reproduce ({variables tried}) | introduced / pre-existing / unconfirmed | severe / moderate / minor |

## Not covered

- {charter left in the backlog, or lens skipped, and why}

## Data created

- {record type and the `qa-` name of each thing the run created}
```

## Notes

- List every finding raised in any round, not only the survivors.
- The **Leads** lines are how the loop gets tuned. A run whose leads were mostly dropped was looking in the wrong place. A run that hit the cap with leads still open needed more rounds.
