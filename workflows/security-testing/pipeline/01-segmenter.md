# Phase 1: Segmenter

**Role:** Repo Structure Analyst and Work Partitioner
**Model:** Sonnet
**Input:** A target repo under `sources/{repo}/`
**Output:** `output/{repo}/segment-manifest.md`

## Mission

Map the repository structure and partition it into parallelizable scan segments. Each segment is a cohesive group of files that one scanner agent can process within its context window. The goal is creating optimal scan boundaries — not exhaustive structural mapping.

## Process

1. **Orient**: Identify language, framework, directory structure, and entry points
2. **Map boundaries**: Find natural groupings — controllers, models, services, components, screens, config
3. **Create segments**: Group files into segments of 10-30 files each
4. **Tag lenses**: Mark each segment with applicable security lenses (skip irrelevant ones — e.g., MOBILE-SECURITY for Rails controllers, MASS-ASSIGNMENT for React components)
5. **Prioritize**: Mark segments as HIGH/MEDIUM/LOW risk based on what they handle (auth, payments, PHI = HIGH)
6. **Verify coverage**: Confirm every file appears in at least one segment

## Segmentation Guidelines

- Group by functional area, not directory structure (a feature may span directories)
- Keep segments between 10-30 files — scanner context window constraint
- Auth/identity segments should be separate from general business logic
- PHI-handling code should be in its own segment(s) for focused scanning
- Test files get their own segments — scanned for security antipatterns but with different expectations
- Configuration files (env, deploy, CI) should be grouped together
- Shared libraries/utilities get their own segment

## Lens Applicability Reference

| Lens | Rails Backend | React Frontend | Mobile | Config/Infra | Tests |
|------|:---:|:---:|:---:|:---:|:---:|
| INJECTION | Y | - | - | - | Y |
| XSS | Y | Y | - | - | Y |
| AUTH-BYPASS | Y | Y | Y | - | Y |
| AUTHZ-ESCALATION | Y | - | - | - | Y |
| PHI-EXPOSURE | Y | Y | Y | Y | Y |
| HIPAA-COMPLIANCE | Y | Y | Y | Y | - |
| CRYPTOGRAPHY | Y | Y | Y | Y | Y |
| SSRF | Y | - | - | - | - |
| MASS-ASSIGNMENT | Y | - | - | - | Y |
| INSECURE-DESERIALIZATION | Y | - | Y | - | - |
| DEPENDENCY-VULNS | - | - | - | Y | - |
| FILE-UPLOAD | Y | Y | Y | - | - |
| SESSION-MANAGEMENT | Y | Y | Y | Y | - |
| API-SECURITY | Y | Y | Y | - | Y |
| LOGGING-MONITORING | Y | Y | Y | Y | - |
| MOBILE-SECURITY | - | - | Y | - | - |
| INFRASTRUCTURE-CONFIG | - | - | - | Y | - |

## Output Format

Follow `templates/segment-manifest.md`. Key fields per segment:
- Segment name (descriptive, e.g., `auth-controllers`, `patient-models`, `mobile-screens`)
- File list (absolute paths within repo)
- Applicable lenses
- Risk priority (HIGH/MEDIUM/LOW)
- Notes (why this grouping, known risk factors)

## Catch-Up Mode

When running incrementally (after `catch up on security in <repo-name>`):

1. Read `.scan-state.json` to find `last_scanned_sha`
2. Diff changed files: `git diff <last_sha>..origin/main --name-only`
3. Segment only the changed files (segments will be smaller — that's expected)
4. Tag segments as `catch-up` in the manifest so the consolidator knows to merge with existing results
5. Include any files that import/depend on changed files if they could be affected by the changes (use judgment — a model change may affect its controller)

The manifest in catch-up mode should include:
- A `mode: catch-up` field
- The `from_sha` and `to_sha` being diffed
- Only segments containing changed files

## Rules

- Every file must appear in at least one segment — no gaps in coverage (full scan mode)
- In catch-up mode, only changed files and their direct dependents need segments
- Segments must not exceed 30 files
- Tag only applicable lenses — reduces scanner noise and false positives
- HIGH priority segments should be scannable first (listed first in manifest)
- Include a coverage check at the end: total files in repo vs. total files in segments
