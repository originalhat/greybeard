# Knowledge Extraction Workflow

A multi-agent pipeline for extracting business logic from code into a living knowledge base. The goal is not API docs—it's surfacing the *decisions, constraints, and rules* that explain *why* the code does what it does.

## Directory Structure

```
knowledge-extraction/
├── CLAUDE.md                  ← You are here
├── pipeline/
│   ├── 01-crawler.md          ← Phase 1: Structural mapping
│   ├── 02-extractor.md        ← Phase 2: Business logic extraction
│   ├── 03-researcher.md       ← Phase 3: Evidence gathering
│   ├── 04-interrogator.md     ← Phase 4: Gap analysis & SME questions
│   └── 05-synthesizer.md      ← Phase 5: Final knowledge base assembly
├── templates/
│   ├── domain-record.md       ← Template for a documented domain
│   ├── open-question.md       ← Template for an unresolved SME question
│   └── ubiquitous-language.md ← Template for domain vocabulary
└── output/
    └── {repo}/                ← Per-repo output
        ├── .extraction-state.json  ← Tracks last extracted SHA for incremental updates
        ├── domains/           ← One file per business domain
        ├── ubiquitous-language.md  ← Domain vocabulary for this repo
        └── open-questions.md  ← Compiled SME questions
```

---

## How It Works

The pipeline runs in five sequential phases. Agents can run in parallel within a phase, but phases must complete before the next begins.

```
Phase 1: Crawl         →  Raw structural map of the codebase
Phase 2: Extract       →  Business rules identified within that structure
Phase 3: Research      →  External evidence gathered (git, tickets, tests, docs)
Phase 4: Interrogate   →  Gaps surfaced as SME questions
Phase 5: Synthesize    →  Everything merged into the final knowledge base
```

---

## Key Concepts

### Domain
A coherent area of business behavior—not necessarily a folder or module. Examples: "subscription billing," "user permissions," "order fulfillment." Domains are identified during extraction, not assumed upfront.

### Business Rule
A specific encoded decision: a threshold, a gate, a special case, a transformation. Each rule gets a confidence level and a source.

### Confidence Levels

| Level | Meaning |
|-------|---------|
| `HIGH` | Confirmed by explicit source (comment, ticket, PR, test name, or SME) |
| `MED` | Reasonably inferred from code structure and context |
| `LOW` | Speculative—agent could not determine intent |

`LOW` confidence items automatically become open questions for SME review.

### Ubiquitous Language
A glossary of domain-specific terms used in the codebase. Captures what terms mean in this context, how they differ from generic usage, and relationships between concepts. Essential for onboarding and preventing miscommunication.

---

## Outputs

### Domain Records (`output/{repo}/domains/`)
One markdown file per domain, following `templates/domain-record.md`. These are the canonical reference for business logic.

### Ubiquitous Language (`output/{repo}/ubiquitous-language.md`)
A glossary of domain terms extracted from the codebase. Includes:
- Term definitions as used in this codebase
- Relationships between terms
- Common confusions or naming quirks
- Cross-repo term alignment notes

### Open Questions (`output/{repo}/open-questions.md`)
Structured questions for SME review where agents couldn't determine intent.

---

## Cross-Repo Analysis

Repos often interact with each other. During extraction:

1. **Identify Integration Points**: Note where code calls or is called by other repos
2. **Compare Terminology**: Flag terms that differ across repos (same word, different meaning)
3. **Trace Data Flow**: Document how entities flow between repos
4. **Check sources/CLAUDE.md**: Understand repo relationships before analyzing

Cross-repo insights should be noted in:
- Domain records under "Boundaries" section
- Ubiquitous language under "Cross-Repo Notes"

---

## Running the Pipeline

### Prerequisites
- Access to the target repo under `sources/`
- Access to git history and commit messages
- Access to linked issue tracker (if available)
- One or more humans available for SME review in Phase 4

### Execution

1. **Phase 1**: Run one crawler agent per top-level domain/service
2. **Phase 2**: Run one extractor agent per crawler output file
3. **Phase 3**: Run one researcher agent per domain
4. **Phase 4**: One interrogator agent synthesizes all gaps into questions
5. **Phase 5**: One synthesizer agent produces the final output + ubiquitous language

### Keeping It Current

- On significant PRs, re-run Phase 2 on changed files only
- On major refactors, re-run the full pipeline for affected domains
- SME answers should be added directly to domain records
- Tag each domain record with the last date it was reviewed

### Incremental Extraction (Catch-Up)

Each repo's output directory contains a `.extraction-state.json` file that tracks the last extracted commit:

```json
{
  "repo": "care_platform",
  "last_extracted_sha": "8305c63c...",
  "last_extracted_at": "2026-04-01T10:45:00Z",
  "domains_updated": ["task-management", "referral-management"],
  "notes": "Brief summary of what was extracted"
}
```

**To catch up on a repo:**

```
catch up knowledge for <repo-name>
```

This will:
1. Read `.extraction-state.json` to find the last extracted SHA
2. Diff from that SHA to current `origin/main`
3. Analyze only the changed files
4. Update affected domain records
5. Update the state file with the new SHA

**Manual diff command:**
```bash
cd sources/<repo> && git fetch origin
git log <last_sha>..origin/main --oneline --no-merges
git diff <last_sha>..origin/main --stat
```

---

## Related

- **sources/CLAUDE.md**: Describes repo relationships and cross-repo considerations
- **workflows/code-review/**: Uses extracted knowledge for contextual code review
