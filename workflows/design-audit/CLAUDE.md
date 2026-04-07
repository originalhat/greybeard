# Design Audit Workflow

A whole-repo design consistency assessment that inventories visual tokens, captures screenshots, analyzes patterns via Claude vision, and synthesizes a living design specification.

## Directory Structure

```
design-audit/
├── CLAUDE.md           # You are here
├── pipeline/           # 4-phase audit process
│   ├── 01-inventorier.md
│   ├── 02-screenshotter.md
│   ├── 03-analyzer.md
│   └── 04-synthesizer.md
├── lenses/             # Design dimensions to evaluate
└── templates/          # Output format templates
```

Output lives at `../greybeard-data/output/design-audit/{repo}/`:
```
{repo}/
├── .design-state.json
├── inventory.md
├── findings.md
└── design-spec.md
```

## Inputs

- A frontend repository cloned under `../greybeard-data/sources/{repo}/`
- Optionally: a running dev server or deployed URL for visual capture

## Outputs

All outputs live under `../greybeard-data/output/design-audit/{repo}/`:

| File | Description |
|------|-------------|
| `.design-state.json` | Tracks last audited SHA for incremental catch-up |
| `inventory.md` | Raw CSS/design metrics extracted from source code |
| `findings.md` | Inconsistencies ranked by severity |
| `design-spec.md` | Living design specification — tokens, patterns, conventions |

The `design-spec.md` is the canonical artifact. The code-review `DESIGN-CONSISTENCY-REVIEWER` lens references it when evaluating PRs, just as `DOMAIN-KNOWLEDGE-REVIEWER` references knowledge-extraction output.

## Execution

**Trigger:** `design audit <repo-name>`

### Pipeline

| Phase | Agent | Purpose | Input | Output |
|-------|-------|---------|-------|--------|
| 1 | Sonnet | Inventorier | Source code | `inventory.md` |
| 2 | Sonnet | Screenshotter | Running app or URL | `screenshots/` |
| 3 | Opus | Analyzer | Inventory + screenshots + lenses | `findings.md` |
| 4 | Opus | Synthesizer | Inventory + findings | `design-spec.md` |

**Phases 1 and 2 run in parallel** — static extraction and visual capture are independent. Phase 3 requires both. Phase 4 requires Phase 3.

### Steps

1. Clone or verify repo under `../greybeard-data/sources/{repo}/`
2. **Parallel**: Run Phase 1 (Inventorier) and Phase 2 (Screenshotter)
   - Phase 2 requires a running app — if unavailable, skip and proceed static-only
3. Run Phase 3 (Analyzer) against inventory, screenshots (if available), and each lens
4. Run Phase 4 (Synthesizer) to produce the living design spec
5. Update `.design-state.json`

### Graceful Degradation

If the app cannot be started or no deployed URL exists:
- Skip Phase 2 (Screenshotter)
- Phase 3 (Analyzer) proceeds with static inventory only
- All findings from static-only analysis are marked with reduced confidence
- Note in output: "Visual capture unavailable — static analysis only"

## Catch-Up Mode

**Trigger:** `catch up design for <repo-name>`

1. Read `.design-state.json` for last audited SHA
2. `git diff {last_sha}..HEAD` to identify changed files
3. Re-run Phase 1 on changed files only, merge with existing inventory
4. Re-capture screenshots for pages affected by changes (if app available)
5. Re-run Phase 3 on updated inventory/screenshots
6. Phase 4 updates the living spec — moves resolved findings to Resolved section
7. Update `.design-state.json` with new SHA

## Components

### Pipeline (`pipeline/`)

Four sequential phases (1+2 parallelizable). Each file specifies role, model, inputs, outputs, process, and rules. See individual phase files for details.

### Lenses (`lenses/`)

Design dimensions evaluated by the Analyzer. Each lens focuses on a single visual concern:

| Lens | Focus |
|------|-------|
| COLOR | Palette consistency, token usage, near-duplicates, semantic misuse |
| TYPOGRAPHY | Font families, size scale, weights, line heights |
| SPACING | Spacing scale, one-off values, mixed units |
| LAYOUT | Breakpoints, responsive behavior, z-index, containers |
| COMPONENTS | Duplicate implementations, inconsistent patterns, missing shared components |

### Templates (`templates/`)

Output format specifications for each artifact. The Synthesizer and Analyzer follow these exactly.

## Cost

Visual analysis uses Claude vision API calls. Approximate cost for a full audit:
- 20 pages x 3 viewports = 60 screenshots
- ~$0.15–0.30 total for vision analysis
- Static-only mode has no additional cost beyond standard token usage

## Notes

- Playwright is required for Phase 2 (visual capture). Install: `npm i -D playwright @playwright/test`
- The design-spec.md should be treated as a living document — re-audit after major UI changes
- Lenses here are audit-specific. The code-review lens (`DESIGN-CONSISTENCY-REVIEWER`) is separate and lives in `workflows/code-review/lenses/`
