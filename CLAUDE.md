# Greybeard

A multi-workflow system for code review and knowledge extraction, powered by AI agents.

## Directory Structure

```
greybeard/
├── workflows/                 # AI-powered workflows
│   ├── code-review/           # Technical code review pipeline
│   │   ├── lenses/            # General technical criteria
│   │   └── context/           # Team/repo-specific criteria
│   └── knowledge-extraction/  # Business logic documentation pipeline
│       ├── pipeline/          # 5-phase extraction process
│       └── templates/         # Output templates
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

## Sources

Clone repositories to analyze into `sources/`. This directory is gitignored.

```bash
git clone <repo-url> sources/<repo-name>
```

When comparing against other repos, always use their `main` branch and pull latest.

## Adding New Workflows

See `workflows/CLAUDE.md` for conventions on creating new workflows.
