# Slice Record

The audit record for one slice. Written once, in step 3, to `$GREYBEARD_DATA/output/improve/{repo}/slices/{YYYY-MM-DD}-{anchor-slug}.md`. It is what a later run or a human reads to learn why the backlog says what it says. PHI-free: paths, symbols, and code only.

## Shape

```markdown
# Slice: {repo} {anchor}

**Ref:** origin/main @ {sha}
**Run:** {ISO timestamp} · {improve | discover}
**Files:** {anchor}, {with}, {with}
**Why this slice:** {reason line from pick-slice.sh}
**Focus:** {path | none}
**Agents:** {group}: LENS-A, LENS-B; {group}: LENS-C, …
**Skipped lenses:** {LENS (no subject in the slice), … | none}
**Evidence found:** {N review-record rows, design-audit F-nnn, security report: none, domain records: …}
**Linters:** {rubocop: 3 offenses | eslint: not run (no local node_modules) | none configured}

## Candidates

Every candidate a scout raised, before any filtering.

| Scout's title | Lens | Where | Outcome | Why |
|---------------|------|-------|---------|-----|
| {title} | {LENS} | {path:line} | I-{n} (new, {label}, {value}/{confidence}) | {one line} |
| {title} | {LENS} | {path:line} | merged into I-{n} | {same fingerprint / same change} |
| {title} | {LENS} | {path:line} | dropped | {fact-check: what did not hold} |
| {title} | {LENS} | {path:line} | low value | {why it isn't worth a branch} |
| {title} | {LENS} | {path:line} | out: needs a ticket | {defect / security / schema / auth / …} |

## Knowledge base changes

- **map.md:** {conventions added, contradicted, or removed | none}
- **patterns.md:** {pattern: k/3 (new | +1) | reached threshold → I-{n} | none}
```
