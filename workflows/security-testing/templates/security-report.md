# Security Report: {repo}

**Last updated:** {date}
**Initial scan:** {date of first full scan}
**Agents:** Segmenter (Sonnet) → Scanners (Sonnet × {N} segments) → Consolidator (Opus)
**Scope:** Full repository scan / Catch-up ({from_sha}..{to_sha})
**Segments scanned:** {N}
**Lenses applied:** {N} of 17

## Executive Summary

**Overall risk:** {CRITICAL / HIGH / MEDIUM / LOW}

| Severity | Count |
|----------|-------|
| CRITICAL | {N} |
| HIGH | {N} |
| MEDIUM | {N} |
| LOW | {N} |
| Dismissed | {N} |
| **Total verified** | **{N}** |

**Top issues requiring immediate attention:**
1. {One-line summary of most critical finding}
2. {One-line summary}
3. {One-line summary}

## Findings

### CRITICAL

#### {ID}: {title}

- **Severity:** CRITICAL
- **Confidence:** CONFIRMED / LIKELY
- **Lens:** {lens}
- **File:** `{path}`
- **Lines:** {range}

**Description:**
{What the vulnerability is.}

**Proof:**
```{language}
{verified code snippet from the actual repo}
```

**Impact:**
{What an attacker could achieve. HIPAA/PHI implications.}

**Remediation:**
{Step-by-step fix with code example.}

**Related findings:** {IDs of related findings, if any}

---

### HIGH

_(same format)_

### MEDIUM

_(same format)_

### LOW

_(same format)_

## Attack Surface Summary

| Area | Risk | Key Findings |
|------|------|-------------|
| {e.g., Authentication} | {HIGH} | {brief summary} |
| {e.g., PHI Handling} | {MEDIUM} | {brief summary} |
| ... | ... | ... |

## Positive Observations

- {Security practice done well — e.g., "Strong parameter filtering consistently applied across all controllers"}
- {e.g., "Audit logging present for all PHI access endpoints"}
- ...

## Resolved

_Findings from previous scans that have been remediated._

### Resolved: {original ID} — {title}

- **Original severity:** {severity}
- **Found:** {date of original scan}
- **Resolved:** {date finding was no longer present}
- **Resolution:** {what changed — e.g., "Input now parameterized in commit abc123"}

---

## Appendix: Dismissed Findings

### Dismissed: {original ID} — {title}

- **Original severity:** {severity}
- **Original confidence:** {confidence}
- **Reason for dismissal:** {why — mitigation found, false positive, code doesn't match scanner report}

---

_(repeat for each dismissed finding)_
