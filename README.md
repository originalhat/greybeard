# Greybeard

AI-powered workflows centererd around code. Built for use with [Claude Code](https://github.com/anthropics/claude-code).

## What is this?

Greybeard is a collection of structured AI agent workflows that help you:

1. **Review code** against technical best practices and team-specific context
2. **Extract knowledge** from codebases into living documentation
3. **Security test** repositories against 17 focused security lenses
4. **Audit design** consistency across frontend codebases
5. **Run campaigns** — systematic large-scale refactoring across many files over multiple sessions
6. **Triage on-call tickets** — investigate incidents, propose fixes, and turn each resolution into durable runbooks

Each workflow is a set of prompts and templates that guide AI agents through multi-stage analysis.

## Directory Structure

```
greybeard/
├── workflows/
│   ├── code-review/           # Technical code review pipeline
│   │   ├── lenses/            # General technical criteria (22 lenses)
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
│   ├── campaign/              # Large-scale refactoring campaign execution
│   │   └── pipeline/          # 6-phase plan → execute → review cycle
│   └── on-call/               # On-call ticket triage + self-improving runbooks
│       ├── pipeline/          # 5-phase triage → publish → capture → curate → sync
│       ├── context/           # Authoring standard + escalation map
│       └── templates/         # Runbook, audit, and index templates
├── sources/                   # Repo relationship docs
└── sketches/                  # Drafts and ideas
```

Private data lives outside the repo:

```
../greybeard-data/
├── sources/                          # Cloned repositories
│   └── {repo}/
└── output/                           # Workflow output
    ├── knowledge-extraction/{repo}/
    ├── security-testing/{repo}/
    ├── design-audit/{repo}/
    ├── campaigns/{repo}/{campaign}/
    └── on-call/                       # Runbooks (by repo/domain) + PHI-free audit logs
```

## Workflows

### ⚙️ Code Review

Multi-stage review that evaluates code changes against:
- **Lenses**: General technical patterns (security, performance, React, TypeScript, etc.)
- **Context**: Team-specific gotchas and conventions

```
review <github PR URL>
```
(also accepts `review <branch-name> in <repo-name>` when there's no PR yet)

**How it works:**
1. Resolve the PR URL to a repo + branch (or use the given branch), then diff against `origin/main`
2. Evaluate in parallel against each lens
3. Evaluate against team context
4. Fact-check findings against the actual codebase
5. Output an impact-first report: a pass/fail/nit tally, numbered failures with a one-sentence fix, then the nits as one line each

See [`workflows/code-review/`](workflows/code-review/) for details.

### 📓 Knowledge Extraction

Extract business logic from code into structured documentation. Produces:
- **Domain records**: Documented business rules with confidence levels
- **Ubiquitous language**: Glossary of domain terms
- **Open questions**: Gaps requiring SME review

**5-phase pipeline:**
1. Crawl → Structural map
2. Extract → Business rules
3. Research → Evidence gathering
4. Interrogate → Gap analysis
5. Synthesize → Final knowledge base

See [`workflows/knowledge-extraction/`](workflows/knowledge-extraction/) for details.

### 🔐 Security Testing

Scan entire repositories for security vulnerabilities. Produces a prioritized report ranked by severity.

```
pen test <repo-name>
```

**How it works:**
1. Segment the repo into parallelizable scan units
2. Scan each segment against applicable security lenses in parallel
3. Consolidate, deduplicate, fact-check, and rank all findings
4. Output a prioritized security report (Critical/High/Medium/Low)

Supports incremental catch-up:
```
catch up security for <repo-name>
```

See [`workflows/security-testing/`](workflows/security-testing/) for details.

### 👓 Design Audit

Scan frontend repositories for design consistency and produce a living design specification.

```
design audit <repo-name>
```

**How it works:**
1. Inventory all design metrics from source code (colors, typography, spacing, layout, components)
2. Capture screenshots at mobile/tablet/desktop viewports via Playwright
3. Analyze inventory + screenshots against design lenses
4. Synthesize a living design specification documenting tokens, patterns, and conventions

Supports incremental catch-up:
```
catch up design for <repo-name>
```

See [`workflows/design-audit/`](workflows/design-audit/) for details.

### 🗂️ Campaign

Execute large-scale, systematic refactoring campaigns across many files over multiple sessions. The human defines the goal; the pipeline writes the recipe, tracks progress, and makes the changes in reviewable batches.

```
campaign plan <goal> in <repo-name>
```

**How it works:**
1. Interpret the goal and write a recipe with done criteria (Planner, Opus)
2. Inventory all in-scope items and assess current status in parallel (Inventorier, Sonnet)
3. Group into prioritized batches (Coordinator, Opus)
4. Execute the batch — one commit per item (Executor, Sonnet, parallel)
5. Verify each item against done criteria (Verifier, Sonnet, parallel)
6. First-pass code review, auto-fix, summarize for human (Reviewer, Opus)
7. Human reviews and merges the batch branch, then continue

Continue an in-progress campaign:
```
campaign continue <campaign-name> in <repo-name>
```

Check progress without making changes:
```
campaign status <campaign-name> in <repo-name>
```

See [`workflows/campaign/`](workflows/campaign/) for details on execution modes (autonomous vs. guided) and DDD campaign integration.

### 📟 On-Call

Triage engineering on-call (ER) tickets and turn each resolution into durable knowledge — a hierarchy of short, self-contained runbooks plus a PHI-free audit trail. Spans `origami_claims`, `care_platform`, and `sana_mobile`. This is the canonical, cross-repo home for on-call knowledge; the `/oncall` slash commands inside `origami_claims` are separate and left as-is.

```
triage <Jira ticket URL>
```

**How it works:**
1. Gather the ticket, classify it (ops change / investigation / bug), match a runbook, and investigate the code
2. **Confirm the root-cause hypothesis with read-only snippets before proposing any data change** — the engineer runs them and reports back (one at a time when they chain; complete, ready-to-paste snippets)
3. Propose a fix — a self-service redirect where possible, otherwise a specific, confirmed change
4. **Publish** the reviewed analysis back to the ticket (confirmation-gated)
5. **Capture** a PHI-free audit entry, create/update runbooks, and log any surfaced code bugs to the **On-call bugs** Linear project
6. **Curate** the corpus over time, and at end of shift **sync** the runbooks into the app repo via a branch + PR

Five verbs: `triage`, `on-call publish`, `on-call capture`, `on-call curate`, `on-call sync`.

Runbooks and audit logs are the source of truth in `../greybeard-data/output/on-call/` — PHI/PII-free (the JIRA ticket ID is the pointer to real identifiers). Needs the `atlassian` (JIRA) MCP configured for the session.

See [`workflows/on-call/`](workflows/on-call/) for details.

## Getting Started

### 1. Clone this repo

```bash
git clone https://github.com/your-org/greybeard.git
cd greybeard
```

### 2. Set up the data directory

```bash
mkdir -p ../greybeard-data/sources ../greybeard-data/output/{knowledge-extraction,security-testing,design-audit,campaigns,on-call}
```

### 3. Add your repositories

Clone the repos you want to analyze into the data directory:

```bash
git clone https://github.com/your-org/your-repo.git ../greybeard-data/sources/your-repo
```

### 4. Customize context (optional)

Add team-specific review criteria to `workflows/code-review/context/`:
- `GOTCHYAS.md` — Known pitfalls
- `NITS.md` — Style preferences

### 5. Run with Claude Code

```bash
claude
```

Then ask Claude to run a workflow:
- `"Review <github PR URL>"`
- `"Extract knowledge from my-repo"`
- `"Pen test my-repo"`
- `"Design audit my-repo"`
- `"Campaign plan 'convert all JS to TypeScript' in my-repo"`
- `"Triage <Jira ticket URL>"`

## Adding Workflows

New workflows go in `workflows/{workflow-name}/` with:
- `CLAUDE.md` — Instructions and execution steps
- Component subdirectories as needed

See [`workflows/CLAUDE.md`](workflows/CLAUDE.md) for conventions.

## Lenses Included

| Category | Lenses |
|----------|--------|
| Security | Auth, PHI/HIPAA |
| React | Hooks, Performance, State |
| TypeScript | Type Safety, Defensive Code |
| Data | N+1 Queries, Migrations, Idempotency |
| Architecture | Separation of Concerns, Extensibility, Clarity |
| Infrastructure | Cron, Jobs, WebSockets |
| Compatibility | API Breaking Changes, Browser, CORS, Client-Server Contracts |
| Quality | Testing, Accessibility |

## License

MIT
