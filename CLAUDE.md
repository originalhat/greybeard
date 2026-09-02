# Greybeard

A multi-workflow system for code review, knowledge extraction, security testing, design analysis, refactoring campaigns, and on-call triage — powered by AI agents. Installable as a Claude Code plugin: install once, run from any project.

## Data Directory

Private data (cloned repos and workflow output) lives **outside the plugin** at `$GREYBEARD_DATA/`, which defaults to `~/.greybeard-data/`. Override it by setting `GREYBEARD_DATA` to point elsewhere (e.g. a shared volume). Keeping it outside the plugin cache protects proprietary source and accumulated output from being wiped on reinstall.

```
$GREYBEARD_DATA/
├── sources/                          # Cloned repositories
│   └── {repo}/
└── output/                           # Workflow output
    ├── knowledge-extraction/{repo}/  # Domain records, language, questions
    ├── security-testing/{repo}/      # Scan results, security reports
    ├── design-audit/{repo}/          # Inventory, findings, design specs
    ├── campaigns/{repo}/{campaign}/  # Campaign strategy, inventory, plan, batch reviews
    ├── code-review/{repo}/fix-runs/  # review-fix audit records (one per run)
    └── on-call/                      # Runbooks (per repo, by domain) and PHI-free audit logs
```

Set up the data directory (one-time):
```bash
mkdir -p "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources" "${GREYBEARD_DATA:-$HOME/.greybeard-data}/output"/{knowledge-extraction,security-testing,design-audit,campaigns,code-review,on-call}
```

This runs automatically on the first session after install (a `SessionStart` hook creates the dirs idempotently), so the manual `mkdir` is only needed if you want to populate `sources/` before launching Claude.

Clone repos to analyze into the data directory:
```bash
git clone <repo-url> "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources/<repo-name>"
```

## Layout

```
greybeard/
├── .claude-plugin/plugin.json   # Plugin manifest
├── skills/                      # One skill per workflow — auto-activates on its trigger words
│   └── <workflow>/SKILL.md      # Thin router → workflows/<workflow>/CLAUDE.md
├── workflows/                   # Shared instruction tree (lenses, pipelines, templates, context)
│   ├── code-review/             # Technical code review pipeline
│   │   ├── lenses/              # General technical criteria
│   │   ├── context/             # Team/repo-specific criteria
│   │   └── templates/           # Canonical report format
│   ├── review-fix/              # Loop-based auto-fix on top of code review
│   │   ├── pipeline/            # 3-phase triage → fix → gate loop
│   │   └── templates/           # Fix-run audit record format
│   ├── knowledge-extraction/    # Business logic documentation pipeline
│   │   ├── pipeline/            # 5-phase extraction process
│   │   └── templates/           # Output templates
│   ├── security-testing/        # Security vulnerability scanning
│   │   ├── pipeline/            # 3-phase scan process
│   │   ├── lenses/              # 17 security-focused lenses
│   │   └── templates/           # Output templates
│   ├── design-audit/            # Frontend design consistency assessment
│   │   ├── pipeline/            # 4-phase audit process
│   │   ├── lenses/              # Design dimension criteria
│   │   └── templates/           # Output templates
│   ├── campaign/                # Large-scale refactoring campaign execution
│   │   └── pipeline/            # 6-phase plan → execute → review cycle
│   └── on-call/                 # On-call ticket triage + self-improving runbooks
│       ├── pipeline/            # 5-phase triage → publish → capture → curate → sync
│       ├── context/             # Authoring standard + escalation map
│       └── templates/           # Runbook, audit entry, and index templates
├── sources/CLAUDE.md            # Repo-relationship docs (edit in place)
└── sketches/                    # Drafts and ideas
```

Each skill is a thin entry point: its `description` carries the trigger words so Claude loads the right one, and its body points at `${CLAUDE_PLUGIN_ROOT}/workflows/<workflow>/CLAUDE.md` for the full pipeline. The `workflows/` tree is the single canonical copy of every lens, template, and pipeline stage.

## Workflows — routing shorthand

The leading word routes the request to a workflow. Match on it directly.

| Say | Runs | Skill | Example |
|-----|------|-------|---------|
| `review` | Code Review | `code-review` | `review https://github.com/sana/origami_claims/pull/8842` |
| `review --fix` | Code Review — Auto-Fix | `code-review` (`--fix`) | `review --fix` (current branch) |
| `review --interactive` | Code Review — Interactive | `code-review` (`--interactive`) | `review --interactive` |
| `triage` | On-Call | `on-call` | `triage https://sanabenefits.atlassian.net/browse/ER-1477` |
| `extract knowledge from` | Knowledge Extraction | `knowledge-extraction` | `extract knowledge from care_platform` |
| `pen test` | Security Testing | `security-testing` | `pen test origami_claims` |
| `design audit` | Design Audit | `design-audit` | `design audit care_platform` |
| `campaign` | Campaign | `campaign` | `campaign plan "…" in origami_claims` |

`review` and `triage` are the two single-word entry points: **`review` always means code review** (of a GitHub PR or branch), and **`triage` always means on-call** (of a JIRA ticket). On-call's other phases keep the `on-call` prefix (`on-call publish/capture/curate/sync`); bare `triage` is the shorthand for starting one. `review --fix` and `review --interactive` stay under the `review` verb because they're the same evaluation with a loop bolted on, not a different concern.

### Code Review
Reviews code changes against technical lenses and team-specific context. `review <github PR URL>` or `review <branch-name> in <repo-name>`. Diffs against `origin/main`, evaluates lenses + context, fact-checks, cross-repo analysis, reports an impact-first tally. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/CLAUDE.md`.

### Code Review — Auto-Fix Mode
Runs the same lenses and context as `review`, but instead of stopping at a report, classifies findings, auto-applies the safe ones, commits them separately from the author's original commits, and re-reviews with a fresh pass — looping (bounded) until nothing auto-fixable remains or a 3-round cap is hit. Never pushes; never runs against a branch you don't own. `review --fix` / `review --fix <branch-name> in <repo-name>`. Pipeline: `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/CLAUDE.md`.

### Code Review — Interactive Mode
Runs the review, prints the report, then walks failures one by one — drafting a PR review comment in the user's voice (concise, question-framed, user-impact focused), revising on feedback, and posting inline to GitHub only after approval. Skips pre-existing findings; nits skipped by default. `review --interactive`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/CLAUDE.md`.

### Knowledge Extraction
Extracts business logic from code into structured documentation. `extract knowledge from <repo>` / `catch up knowledge for <repo>`. 5-phase pipeline → domain records, ubiquitous language, open questions. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/knowledge-extraction/CLAUDE.md`.

### Security Testing
Scans entire repositories for security vulnerabilities against 17 focused lenses. `pen test <repo>` / `catch up security for <repo>`. Prioritized Critical/High/Medium/Low report; incremental catch-up via `.scan-state.json`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/security-testing/CLAUDE.md`.

### Design Audit
Scans frontend repositories for design consistency and produces a living design specification. `design audit <repo>` / `catch up design for <repo>`. The `design-spec.md` output feeds the code-review `DESIGN-CONSISTENCY-REVIEWER` lens. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/design-audit/CLAUDE.md`.

### Campaign
Executes large-scale, systematic refactoring campaigns across many files over multiple sessions. `campaign plan <goal> in <repo>`, `campaign continue <campaign> in <repo>`, `campaign status <campaign> in <repo>`. Details (execution modes, DDD integration): `${CLAUDE_PLUGIN_ROOT}/workflows/campaign/CLAUDE.md`.

### On-Call
Triages engineering on-call (ER) tickets and turns every resolution into durable knowledge — runbooks plus a PHI-free audit trail. Spans `origami_claims` (primary), `care_platform`, and `sana_mobile`. `triage <Jira ticket URL>` / `triage ER-1477`. Five verbs: `triage`, `on-call publish`, `on-call capture`, `on-call curate`, `on-call sync`. Runbooks/audit logs are the source of truth in `$GREYBEARD_DATA/output/on-call/` (PHI/PII-free). Needs the `atlassian` (JIRA) MCP — declared in the plugin's `.mcp.json`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/on-call/CLAUDE.md`.

## Sources

Clone repositories to analyze into the data directory (see above). See `sources/CLAUDE.md` for repo-relationship documentation. When comparing against other repos, always use their `main` branch and pull latest.

## Adding New Workflows

See `${CLAUDE_PLUGIN_ROOT}/workflows/CLAUDE.md` for conventions on creating new workflows and their matching skill entry points.
