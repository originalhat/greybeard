# Greybeard

A multi-workflow system for code review, implementation, knowledge extraction, security testing, design analysis, refactoring campaigns, and on-call triage — powered by AI agents. Installable as a Claude Code plugin: install once, run from any project.

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
    ├── code-review/{repo}/runs/      # plain review run records (one per review)
    ├── on-call/                      # Runbooks (per repo, by domain) and PHI-free audit logs
    ├── validate/{repo}/              # Validation reports (one per run)
    └── retro/                        # Retro state, reports, designs, changelog (default; override with $RETRO_HOME → a private repo)
```

Set up the data directory (one-time):
```bash
mkdir -p "${GREYBEARD_DATA:-$HOME/.greybeard-data}/sources" "${GREYBEARD_DATA:-$HOME/.greybeard-data}/output"/{knowledge-extraction,security-testing,design-audit,campaigns,code-review,on-call,validate,retro}
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
├── hooks/hooks.json             # SessionStart hook: creates $GREYBEARD_DATA dirs
├── hooks/sync-skills-if-changed.sh  # Stop hook (user settings): re-runs skills/sync-local.sh when a SKILL.md changed
├── agents/                      # Custom subagents (canonical Claude Code frontmatter)
│   └── sync-local.sh            # Generates ~/.claude/agents + ~/.pi/agent/agents copies
├── skills/                      # One skill per workflow — auto-activates on its trigger words
│   └── <workflow>/SKILL.md      # Thin router → workflows/<workflow>/AGENTS.md
├── workflows/                   # Shared instruction tree (lenses, pipelines, templates, context)
│   ├── code-review/             # Technical code review pipeline
│   │   ├── lenses/              # General technical criteria
│   │   ├── context/             # Team/repo-specific criteria
│   │   └── templates/           # Canonical report format
│   ├── review-fix/              # Loop-based auto-fix on top of code review
│   │   ├── pipeline/            # 3-phase triage → fix → gate loop
│   │   └── templates/           # Fix-run audit record format
│   ├── implement/               # Ticket/requirements → TDD → review --fix
│   ├── validate/                # Browser-driven acceptance check + optional exploratory testing
│   │   ├── pipeline/            # Acceptance check → optional bounded exploratory loop
│   │   └── templates/           # Validation report format
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
│   │   ├── context/             # Archetype-specific gotchas
│   │   └── pipeline/            # 6-phase plan → execute → review cycle
│   ├── on-call/                 # On-call ticket triage + self-improving runbooks
│   │   ├── pipeline/            # 5-phase triage → publish → capture → curate → sync
│   │   ├── context/             # Authoring standard + escalation map
│   │   └── templates/           # Runbook, audit entry, and index templates
│   └── retro/                   # Retrospective over recent threads → quantified, ranked improvements
│       ├── pipeline/            # 5-phase gather → summarize → synthesize → report → apply
│       └── templates/           # Report, thread summary, state schema
├── sources/AGENTS.md            # Repo-relationship docs (edit in place)
└── sketches/                    # Drafts and ideas
```

Each skill is a thin entry point: its `description` carries the trigger words so Claude loads the right one, and its body points at `${CLAUDE_PLUGIN_ROOT}/workflows/<workflow>/AGENTS.md` for the full pipeline. The `workflows/` tree is the single canonical copy of every lens, template, and pipeline stage.

## Workflows — routing shorthand

The leading word routes the request to a workflow. Match on it directly.

| Say | Runs | Skill | Example |
|-----|------|-------|---------|
| `review` | Code Review | `code-review` | `review https://github.com/sana/origami_claims/pull/8842` |
| `review --fix` | Code Review — Auto-Fix | `code-review` (`--fix`) | `review --fix` (current branch) |
| `review --interactive` | Code Review — Interactive | `code-review` (`--interactive`) | `review --interactive` |
| `implement` | Implement | `implement` | `implement https://sanabenefits.atlassian.net/browse/ER-1477` |
| `validate` | Validate | `validate` | `validate ER-1477` |
| `validate --exploratory` | Validate — Exploratory | `validate` (`--exploratory`) | `validate ER-1477 --exploratory` |
| `triage` | On-Call | `on-call` | `triage https://sanabenefits.atlassian.net/browse/ER-1477` |
| `extract knowledge from` | Knowledge Extraction | `knowledge-extraction` | `extract knowledge from care_platform` |
| `pen test` | Security Testing | `security-testing` | `pen test origami_claims` |
| `design audit` | Design Audit | `design-audit` | `design audit care_platform` |
| `campaign` | Campaign | `campaign` | `campaign plan "…" in origami_claims` |
| `retro` | Retro | `retro` | `retro`, `retro --days 7`, `retro walkthrough` |

`review` and `triage` are the two single-word entry points: **`review` always means code review** (of a GitHub PR or branch), and **`triage` always means on-call** (of a JIRA ticket). On-call's other phases keep the `on-call` prefix (`on-call publish/capture/curate/sync`); bare `triage` is the shorthand for starting one. `review --fix` and `review --interactive` stay under the `review` verb because they're the same evaluation with a loop bolted on, not a different concern.

### Code Review
Reviews code changes against technical lenses and team-specific context. `review <github PR URL>` or `review <branch-name> in <repo-name>`. Diffs against `origin/main`, reads the target repo's own `CLAUDE.md` docs, evaluates lenses + context, fact-checks findings and the PR description's premises, cross-repo analysis, reports an impact-first tally. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/AGENTS.md`.

### Code Review — Auto-Fix Mode
Runs the same lenses and context as `review`, but instead of stopping at a report, classifies findings, auto-applies the safe ones, commits them separately from the author's original commits, and re-reviews with a fresh pass — looping (bounded) until nothing auto-fixable remains or a 3-round cap is hit. Never pushes; never runs against a branch you don't own. `review --fix` / `review --fix <branch-name> in <repo-name>`. Pipeline: `${CLAUDE_PLUGIN_ROOT}/workflows/review-fix/AGENTS.md`.

### Code Review — Interactive Mode
Runs the review, prints the report, then walks failures one by one — drafting a PR review comment in the user's voice (concise, question-framed, user-impact focused), revising on feedback, and posting inline to GitHub only after approval. Skips pre-existing findings; nits skipped by default. `review --interactive`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/AGENTS.md`.

### Implement
Takes a ticket or a set of requirements and turns it into working, tested, reviewed code on a branch — test-first (red then green, testing behavior not implementation), then reviewed and auto-fixed via `review --fix`. `implement <Jira ticket URL | ticket ID | GitHub issue URL | freeform requirements>`, optionally `in <repo>`, `--skip-ui`, `--pr`. Picks the smallest design that meets the criteria and reports the alternative as not built; render-checks UI changes with one screenshot per page. Never pushes or opens a PR unless `--pr` is passed, which opens a draft. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/implement/AGENTS.md`.

### Validate
Drives a real browser against a running app to check a change against acceptance criteria — the browser-validation step that used to live inside `implement`, now standalone so it can run against any branch and be re-run after a fix. `validate <Jira ticket URL | ticket ID | GitHub issue URL | freeform requirements>`, optionally `in <repo>`. Add `--exploratory` for a bounded, loop-based round of open-ended testing beyond the stated criteria (adjacent flows, boundary inputs, navigation/reload state), producing a separate findings list ranked by severity. Read-only — never modifies code, never commits. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/validate/AGENTS.md`.

### Knowledge Extraction
Extracts business logic from code into structured documentation. `extract knowledge from <repo>` / `catch up knowledge for <repo>`. 5-phase pipeline → domain records, ubiquitous language, open questions. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/knowledge-extraction/AGENTS.md`.

### Security Testing
Scans entire repositories for security vulnerabilities against 17 focused lenses. `pen test <repo>` / `catch up security for <repo>`. Prioritized Critical/High/Medium/Low report; incremental catch-up via `.scan-state.json`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/security-testing/AGENTS.md`.

### Design Audit
Scans frontend repositories for design consistency and produces a living design specification. `design audit <repo>` / `catch up design for <repo>`. The `design-spec.md` output feeds the code-review `DESIGN-CONSISTENCY-REVIEWER` lens. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/design-audit/AGENTS.md`.

### Campaign
Executes large-scale, systematic refactoring campaigns across many files over multiple sessions. `campaign plan <goal> in <repo>`, `campaign continue <campaign> in <repo>`, `campaign status <campaign> in <repo>`. Details (execution modes, DDD integration): `${CLAUDE_PLUGIN_ROOT}/workflows/campaign/AGENTS.md`.

### On-Call
Triages engineering on-call (ER) tickets and turns every resolution into durable knowledge — runbooks plus a PHI-free audit trail. Spans `origami_claims` (primary), `care_platform`, and `sana_mobile`. `triage <Jira ticket URL>` / `triage ER-1477`. Five verbs: `triage`, `on-call publish`, `on-call capture`, `on-call curate`, `on-call sync`. Runbooks/audit logs are the source of truth in `$GREYBEARD_DATA/output/on-call/` (PHI/PII-free). Needs the `atlassian` (JIRA) MCP — declared in the plugin's `.mcp.json`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/on-call/AGENTS.md`.

### Retro
A retrospective over recent bb threads: quantifies recurring friction (corrections, steers, failed commands, minutes lost) and proposes the most deterministic fix for each pattern, ranked on a fix ladder — config and tooling first, structure, skill mechanics, memory, prose rules last. Walks the suggestions one at a time for approval and applies, records, and commits what is approved. `retro` (since last run), `retro --days 7`, `retro --report-only`, `retro walkthrough`, `retro apply S-…`, `retro reject S-…`, `retro status`. State, reports, designs, and changelog live in `$RETRO_HOME` (default `$GREYBEARD_DATA/output/retro/`; point it at a private repo). Its own threads carry `[retro]`. Details: `${CLAUDE_PLUGIN_ROOT}/workflows/retro/AGENTS.md`.

## Sources

Clone repositories to analyze into the data directory (see above). See `sources/AGENTS.md` for repo-relationship documentation. When comparing against other repos, always use their `main` branch and pull latest.

## Adding New Workflows

See `${CLAUDE_PLUGIN_ROOT}/workflows/AGENTS.md` for conventions on creating new workflows and their matching skill entry points.
