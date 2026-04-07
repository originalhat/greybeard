# Greybeard

A multi-workflow system for code review, knowledge extraction, and design analysis, powered by AI agents.

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
│   │   ├── templates/         # Output templates
│   │   └── output/            # Generated reports per repo
│   └── design-audit/          # Frontend design consistency assessment
│       ├── pipeline/          # 4-phase audit process
│       ├── lenses/            # Design dimension criteria
│       ├── templates/         # Output templates
│       └── output/            # Generated artifacts per repo
├── sources/                   # Cloned repositories (gitignored)
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
1. Check out the branch under `sources/{repo}/`
2. Fetch latest (`git fetch origin`) then diff using three-dot syntax (`git diff origin/main...HEAD`)
3. Evaluate against each lens in `workflows/code-review/lenses/`
4. Evaluate against `workflows/code-review/context/`
5. Fact-check findings in the repo
6. Cross-repo analysis if changes touch integration points (pull latest on related repos first)
7. Output PASS/FAIL per lens with locations and fixes

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
catch up on security in <repo-name>
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
catch up on design in <repo-name>
```
Diffs from last audited SHA, re-inventories only changed files, and updates the living spec.

## Sources

Clone repositories to analyze into `sources/`. This directory is gitignored.

```bash
git clone <repo-url> sources/<repo-name>
```

When comparing against other repos, always use their `main` branch and pull latest.

## Adding New Workflows

See `workflows/CLAUDE.md` for conventions on creating new workflows.
