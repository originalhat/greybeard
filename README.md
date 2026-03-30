# Greybeard

AI-powered workflows for code review and knowledge extraction. Built for use with [Claude Code](https://github.com/anthropics/claude-code).

## What is this?

Greybeard is a collection of structured AI agent workflows that help you:

1. **Review code** against technical best practices and team-specific context
2. **Extract knowledge** from codebases into living documentation

Each workflow is a set of prompts and templates that guide AI agents through multi-stage analysis.

## Directory Structure

```
greybeard/
├── workflows/
│   ├── code-review/           # Technical code review pipeline
│   │   ├── lenses/            # General technical criteria (22 lenses)
│   │   └── context/           # Team/repo-specific criteria
│   └── knowledge-extraction/  # Business logic documentation pipeline
│       ├── pipeline/          # 5-phase extraction process
│       └── templates/         # Output templates
├── sources/                   # Clone your repos here
└── sketches/                  # Drafts and ideas
```

## Workflows

### Code Review

Multi-stage review that evaluates code changes against:
- **Lenses**: General technical patterns (security, performance, React, TypeScript, etc.)
- **Context**: Team-specific gotchas and conventions

```
review <branch-name> in <repo-name>
```

**How it works:**
1. Diff the branch against `origin/main`
2. Evaluate in parallel against each lens
3. Evaluate against team context
4. Fact-check findings against the actual codebase
5. Output PASS/FAIL per lens with locations and fixes

See [`workflows/code-review/`](workflows/code-review/) for details.

### Knowledge Extraction

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

## Getting Started

### 1. Clone this repo

```bash
git clone https://github.com/your-org/greybeard.git
cd greybeard
```

### 2. Add your repositories

Clone the repos you want to analyze into `sources/`:

```bash
git clone https://github.com/your-org/your-repo.git sources/your-repo
```

### 3. Customize context (optional)

Add team-specific review criteria to `workflows/code-review/context/`:
- `GOTCHYAS.md` — Known pitfalls
- `NITS.md` — Style preferences

### 4. Run with Claude Code

```bash
claude
```

Then ask Claude to run a workflow:
- `"Review feature-branch in my-repo"`
- `"Extract knowledge from my-repo"`

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
