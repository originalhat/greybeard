# Greybeard

A multi-workflow system for code review, knowledge extraction, and design analysis, powered by AI agents.

## Data Directory

Private data (cloned repos and workflow output) lives **outside this repo** at `../greybeard-data/`, a sibling directory. This keeps proprietary source code and generated reports structurally separated from the prompts and templates in this repo.

```
../greybeard-data/
├── sources/                          # Cloned repositories
│   └── {repo}/
└── output/                           # Workflow output
    ├── knowledge-extraction/{repo}/  # Domain records, language, questions
    ├── security-testing/{repo}/      # Scan results, security reports
    ├── design-audit/{repo}/          # Inventory, findings, design specs
    └── campaigns/{repo}/{campaign}/  # Campaign strategy, inventory, plan, batch reviews
```

Set up the data directory:
```bash
mkdir -p ../greybeard-data/sources ../greybeard-data/output/{knowledge-extraction,security-testing,design-audit,campaigns}
```

## Directory Structure

```
greybeard/
├── workflows/                 # AI-powered workflows
│   ├── code-review/           # Technical code review pipeline
│   │   ├── lenses/            # General technical criteria
│   │   └── context/           # Team/repo-specific criteria
│   ├── knowledge-extraction/  # Business logic documentation pipeline
│   │   ├── pipeline/          # 5-phase extraction process
│   │   └── templates/         # Output templates
│   ├── security-testing/      # Security vulnerability scanning
│   │   ├── pipeline/          # 3-phase scan process
│   │   ├── lenses/            # 17 security-focused lenses
│   │   └── templates/         # Output templates
│   ├── design-audit/          # Frontend design consistency assessment
│   │   ├── pipeline/          # 4-phase audit process
│   │   ├── lenses/            # Design dimension criteria
│   │   └── templates/         # Output templates
│   └── campaign/              # Large-scale refactoring campaign execution
│       └── pipeline/          # 6-phase plan → execute → review cycle
├── sources/                   # Repo relationship docs (repos cloned into ../greybeard-data/sources/)
└── sketches/                  # Drafts and ideas
```

## Workflows

Each workflow has its own directory under `workflows/` with a `CLAUDE.md` containing detailed instructions.

### Code Review

Reviews code changes against technical lenses and team-specific context.

**To run:**
```
review <branch-name> in <repo-name>
```

**Steps:**
1. Check out the branch under `../greybeard-data/sources/{repo}/`
2. Fetch latest (`git fetch origin`) then diff using three-dot syntax (`git diff origin/main...HEAD`)
3. Fetch PR description if a PR exists (title, body, linked issues) for additional context
4. Evaluate against each lens in `workflows/code-review/lenses/`
5. Evaluate against `workflows/code-review/context/`
6. Fact-check findings in the repo
7. Cross-repo analysis if changes touch integration points (pull latest on related repos first)
8. Output PASS/FAIL per lens with locations and fixes

### Knowledge Extraction

Extracts business logic from code into structured documentation.

**To run:**
```
extract knowledge from <repo-name>
```

**Steps:**
1. Run the 5-phase pipeline in `workflows/knowledge-extraction/pipeline/`
2. Output domain records, ubiquitous language, and open questions
3. Cross-repo analysis for integration points and term alignment

**To catch up:**
```
catch up knowledge for <repo-name>
```

### Security Testing

Scans entire repositories for security vulnerabilities against 17 focused security lenses.

**To run:**
```
pen test <repo-name>
```

**Steps:**
1. Segment the repo into parallelizable scan units (Sonnet)
2. Scan each segment against applicable security lenses in parallel (Sonnet, one agent per segment)
3. Consolidate, deduplicate, fact-check, and rank all findings (Opus)
4. Output a prioritized security report (Critical/High/Medium/Low)
5. Save `.scan-state.json` for incremental catch-up

**To catch up:**
```
catch up security for <repo-name>
```
Diffs from last scanned SHA, re-scans only changed files, and updates the living report.

### Design Audit

Scans frontend repositories for design consistency and produces a living design specification.

**To run:**
```
design audit <repo-name>
```

**Steps:**
1. Inventory all design metrics from source code — colors, typography, spacing, layout, components (Sonnet)
2. Capture screenshots at mobile/tablet/desktop viewports via Playwright (Sonnet, parallel with step 1)
3. Analyze inventory + screenshots against design lenses (Opus, vision)
4. Synthesize a living design specification documenting tokens, patterns, and conventions (Opus)
5. Save `.design-state.json` for incremental catch-up

The `design-spec.md` output is referenced by the `DESIGN-CONSISTENCY-REVIEWER` code review lens to give design feedback on PRs.

**To catch up:**
```
catch up design for <repo-name>
```
Diffs from last audited SHA, re-inventories only changed files, and updates the living spec.

### Campaign

Executes large-scale, systematic refactoring campaigns — migrations, architectural transitions, coverage sweeps — across many files over multiple sessions. The human defines the goal; the pipeline writes the recipe, tracks progress, and makes the changes in reviewable batches.

**To start:**
```
campaign plan <goal> in <repo-name>
```
Example: `campaign plan "convert all JS components to TypeScript" in care_platform`

**Steps:**
1. Interpret the goal and write a recipe with done criteria (Opus)
2. Inventory all in-scope items and assess current status in parallel (Sonnet)
3. Group into prioritized batches, produce plan and state file (Opus)

**To continue (execute next batch):**
```
campaign continue <campaign-name> in <repo-name>
```

**Steps:**
1. Execute next batch — one commit per item, branch per batch (Sonnet, parallel)
2. Verify each item against done criteria (Sonnet, parallel)
3. Run first-pass code review, auto-fix unambiguous issues, summarize for human (Opus)
4. Re-coordinate: update plan and state file for the next batch (Opus)
5. Human reviews and merges the batch branch, then repeat

**To check progress (read-only):**
```
campaign status <campaign-name> in <repo-name>
```

See `workflows/campaign/CLAUDE.md` for full details including execution modes (autonomous vs. guided) and knowledge-extraction integration for DDD campaigns.

## Sources

Clone repositories to analyze into the data directory:

```bash
git clone <repo-url> ../greybeard-data/sources/<repo-name>
```

See `sources/CLAUDE.md` for repo relationship documentation.

When comparing against other repos, always use their `main` branch and pull latest.

## Adding New Workflows

See `workflows/CLAUDE.md` for conventions on creating new workflows.
