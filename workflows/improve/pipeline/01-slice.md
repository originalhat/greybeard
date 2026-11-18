# Step 1: Slice

**Who:** the round's subagent
**Input:** the repo checkout, `--focus` if given, the data directory
**Output:** the slice (files + ref), the existing evidence for it, and the lens groups for step 2

## 1. Pick the slice

From the checkout:

```bash
${CLAUDE_PLUGIN_ROOT}/workflows/improve/scripts/pick-slice.sh {repo} [--focus <path> | --focus perf]
```

It reads `origin/main` only, never the working tree, so the checkout can be on any branch and dirty. The anchor is the eligible file with the highest score. The score is commits in the last 6 months, plus 2 × its `pre-existing` findings in the repo's code-review run records, plus its weight in `hotspots.tsv` (20 for the file behind the most production time, down to 1; `pipeline/00-hotspots.md`). With `--focus perf`, only hotspot files can be anchors. Test files, generated files, migrations, config, and dependency manifests are never anchors. Files visited at a ref they haven't changed since are skipped. The `with` files are the ones that most often change in the same commit as the anchor, usually its spec and a close collaborator.

- `none`: every eligible file (under `--focus`) was visited and hasn't changed. In `improve`, skip to step 4 with the existing backlog and say `Slice: none` in the round report. In `discover`, say so and stop.
- In a batch run, also skip an anchor an earlier round of this run already scouted; the brief lists them.
- Keep the `ref` line. Every file in this slice is read at that SHA, and every candidate records it.

## 2. Gather what is already known

These are deterministic and cheap. They run before any agent and become the scouts' strongest evidence.

- **Production hotspots.** The `hotspots.tsv` line for each slice file: its endpoints or jobs with p95 and hits over 7 days. For a client slice, also any hotspot endpoint the slice calls (find the API path in the component and match it to its controller). This is `apm` evidence: it says the code is slow in production, though not yet why.

- **Review records.** `grep -h '| pre-existing |' $GREYBEARD_DATA/output/code-review/{repo}/runs/*.md`, keeping the rows whose `file:line` names a slice file (full path or a trailing part of it). Each is a finding an Opus fact-check already confirmed and nobody owned.
- **Design audit.** In `$GREYBEARD_DATA/output/design-audit/{repo}/findings.md`, the findings that name a slice file. Also read the `design-spec.md` sections on its component patterns, which say which component is the standard.
- **Security report.** In `$GREYBEARD_DATA/output/security-testing/{repo}/security-report.md`, the findings that name a slice file. These go straight into step 3 as `out` candidates citing the report. They are not scouted again.
- **Knowledge base.** In `$GREYBEARD_DATA/output/knowledge-extraction/{repo}/domains/`, the domain records that name a slice file. Their business rules are the context for `DOMAIN-KNOWLEDGE`.
- **Repo docs on the path.** `CLAUDE.md` or `README.md` in each directory from the root to each slice file, at the ref.
- **Linters, when they run locally in under a minute.** Run the repo's own linters on the slice files only, the way its docs or CI run them (care_platform: `bundle exec rubocop <rb files>` and, from `client/`, `yarn eslint <ts/tsx files>`). An offense is deterministic evidence. If a linter can't run (no local toolchain, the stack is down), say so in one line in the slice record and move on. Don't start a stack for it.
- **This repo's knowledge base.** `map.md` and the names and one-liners from `patterns.md`.

## 3. Choose the lens groups

Choose from `${CLAUDE_PLUGIN_ROOT}/workflows/code-review/lenses/`, keeping only the lenses whose subject is actually in the slice. JOB-CONFIGURATION needs a job, WEBSOCKET-BROADCAST a channel or broadcast, REACT-* a component or hook.

| Group | Lenses |
|-------|--------|
| Design | CLARITY-SIMPLICITY, OBJECT-DESIGN, SEPARATION-OF-CONCERNS, EXTENSIBILITY |
| Tests and rules | TESTING-COVERAGE, INVARIANTS, DOMAIN-KNOWLEDGE (only with a domain record from section 2) |
| Data and jobs | N-PLUS-ONE-QUERY, QUERY-EFFICIENCY, IDEMPOTENCY, CONCURRENCY-LOCKING, BULK-WRITE-SAFETY, TRIGGER-COVERAGE, EXTERNAL-INTEGRATION-RESILIENCE, JOB-CONFIGURATION, CRON, WEBSOCKET-BROADCAST, ROUTE-URL-HELPER-CONTEXT |
| Frontend | REACT-HOOKS, REACT-STATE, REACT-PERFORMANCE, TYPESCRIPT-TYPE-SAFETY, TYPESCRIPT-DEFENSIVE-CODE, CLIENT-SERVER-DATA-CONTRACT, BROWSER-COMPATIBILITY |
| UI | DESIGN-CONSISTENCY (only with a design spec), ACCESSIBILITY |

- **A hotspot slice** (any slice file in `hotspots.tsv`, or `--focus perf`) always gets a **Performance** group of its own: N-PLUS-ONE-QUERY and QUERY-EFFICIENCY for server files, REACT-PERFORMANCE for client files, with the APM lines in its material.
- At most four lenses per agent. Split a group that ends up with more after filtering (e.g. Data and jobs into queries/writes and jobs/integrations). Never move a Design lens into another group: the design axis goes quiet when it shares an agent with defect hunting, as the code-review pipeline found.
- **Never run here.** API-BREAKING-CHANGES, DATA-MIGRATION, BEHAVIORAL-PARITY, and OPPORTUNISTIC-REFACTOR judge a change against what came before, and there is no change yet. AUTH-SECURITY, PHI-PII-HIPAA, EMBEDDED-INTEGRATION-SECURITY, and CROSS-ORIGIN-REQUEST belong to `security-testing`, and anything they found would be `out` anyway.
- A slice of three small files usually needs 2-4 agents. Write the groups down. They go in the slice record.
