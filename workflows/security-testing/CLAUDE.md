# Security Testing Workflow

A whole-repo security assessment pipeline that segments codebases into parallelizable units, scans each against focused security lenses, then consolidates and fact-checks findings into a prioritized vulnerability report.

## Directory Structure

```
security-testing/
├── CLAUDE.md           # You are here
├── pipeline/           # 3-phase orchestration
│   ├── 01-segmenter.md # Partition repo into scan units
│   ├── 02-scanner.md   # Per-segment vulnerability scanning
│   └── 03-consolidator.md # Dedup, fact-check, rank
├── lenses/             # 17 security vulnerability lenses
└── templates/          # Output format templates
```

Output lives at `../greybeard-data/output/security-testing/{repo}/`:
```
{repo}/
├── .scan-state.json        # Tracks last scanned SHA for incremental catch-up
├── segment-manifest.md     # Repo partitioning map
├── scans/                  # Per-segment raw findings (working artifacts)
│   └── scan-{segment}.md
└── security-report.md     # Final prioritized vulnerability report
```

## Inputs

- A target repository cloned under `../greybeard-data/sources/{repo}/`

## Outputs

Per-repo living records under `../greybeard-data/output/security-testing/{repo}/`:

- `.scan-state.json` — tracks last scanned SHA for incremental catch-up
- `segment-manifest.md` — repo partitioning map
- `scans/scan-{segment}.md` — per-segment raw findings (working artifacts)
- `security-report.md` — final prioritized vulnerability report (the living record)

## Execution

```
pen test <repo-name> # or security scan <repo name>
```

### Model Tiers

- **Phase 1 (Segmenter):** Sonnet — structural mapping is straightforward
- **Phase 2 (Scanner):** Sonnet — parallel adversarial pattern matching, fast and cost-effective
- **Phase 3 (Consolidator):** Opus — deep fact-checking, cross-referencing, severity judgment

### Steps

1. **Segment** (one Sonnet agent): Run `pipeline/01-segmenter.md` against `../greybeard-data/sources/{repo}/`. Produces a segment manifest partitioning the repo into groups of 10-30 files, each tagged with applicable lenses and risk priority.

2. **Scan** (one Sonnet agent per segment, parallel): For each segment in the manifest, run `pipeline/02-scanner.md`. Each scanner agent reads every file in its segment and evaluates against all applicable lenses from `lenses/`. Produces raw vulnerability findings with confidence levels.

3. **Consolidate** (one Opus agent): Run `pipeline/03-consolidator.md` across all scan outputs. Deduplicates findings, fact-checks each against the actual code, classifies severity (Critical/High/Medium/Low calibrated to healthcare/HIPAA context), and produces the final security report.

## Components

### Pipeline (`pipeline/`)

Three-phase orchestration:
- **Segmenter**: Partitions repo into parallelizable scan units, tags applicable lenses per segment
- **Scanner**: Reads every file in a segment, evaluates against security lenses, produces raw findings
- **Consolidator**: Merges all scanner outputs, verifies against actual code, ranks by severity

### Lenses (`lenses/`)

17 focused vulnerability category lenses. Each under 100 lines, covering a single security concern with patterns, severity guidance, and false positive filters. Grouped:

| Category | Lenses |
|----------|--------|
| OWASP Core | INJECTION, XSS, AUTH-BYPASS, AUTHZ-ESCALATION, SSRF, MASS-ASSIGNMENT, INSECURE-DESERIALIZATION, FILE-UPLOAD |
| Healthcare | PHI-EXPOSURE, HIPAA-COMPLIANCE |
| Crypto | CRYPTOGRAPHY |
| Session & API | SESSION-MANAGEMENT, API-SECURITY |
| Supply Chain | DEPENDENCY-VULNS |
| Ops & Config | LOGGING-MONITORING, INFRASTRUCTURE-CONFIG |
| Mobile | MOBILE-SECURITY |

### Templates (`templates/`)

Output format templates for each phase's deliverables.

## Relationship to Code Review

Security testing is complementary to code review, not a replacement:
- **Code review** lenses (AUTH-SECURITY, PHI-PII-HIPAA) catch issues in branch diffs — surface-level, change-scoped
- **Security testing** scans the entire codebase — deep, comprehensive, whole-repo

## Keeping It Current

### Scan State

Each repo's output directory contains a `.scan-state.json` file that tracks the last scanned commit:

```json
{
  "repo": "care_platform",
  "last_scanned_sha": "abc123...",
  "last_scanned_at": "2026-04-05T14:30:00Z",
  "findings_summary": { "critical": 0, "high": 2, "medium": 5, "low": 3 },
  "segments_scanned": 12,
  "notes": "Full initial scan. 2 HIGH findings in auth controllers."
}
```

### Incremental Scan (Catch-Up)

```
catch up security for <repo-name>
```

This will:
1. Read `.scan-state.json` to find the last scanned SHA
2. Diff from that SHA to current `origin/main` to identify changed files
3. Re-segment only the changed files (the segmenter runs in catch-up mode — smaller, targeted segments)
4. Scan only the affected segments against applicable lenses
5. Merge new findings into the existing security report — re-verify any previous findings in changed files (they may be fixed or changed)
6. Update `.scan-state.json` with the new SHA

**Manual diff command:**
```bash
cd ../greybeard-data/sources/<repo> && git fetch origin
git log <last_sha>..origin/main --oneline --no-merges
git diff <last_sha>..origin/main --stat
```

### Living Report

The `security-report.md` is a living document. On catch-up scans:
- New findings are added with the scan date
- Fixed findings are moved to a "Resolved" section (not deleted — keeps history)
- Changed findings are re-verified and updated
- The executive summary reflects the current state

## Notes

- Scanner agents should receive no more than 30 files + applicable lenses to stay within context limits
- Every file in the repo must appear in at least one segment (no coverage gaps)
- The consolidator must verify every finding against actual code — no finding survives on scanner assertion alone
- Severity is calibrated to healthcare/HIPAA: a vulnerability that would be MEDIUM in a consumer app may be CRITICAL when it involves PHI
