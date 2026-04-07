# Scan Result: {segment-name}

**Date:** {date}
**Agent:** Scanner (Sonnet)
**Segment:** {segment-name}
**Files scanned:** {N}
**Lenses applied:** {comma-separated list}

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {N} |
| HIGH | {N} |
| MEDIUM | {N} |
| LOW | {N} |
| **Total** | **{N}** |

## Findings

### Finding: {ID} — {title}

- **Lens:** {lens name}
- **Severity:** CRITICAL / HIGH / MEDIUM / LOW
- **Confidence:** CONFIRMED / LIKELY / POSSIBLE
- **File:** `{path}`
- **Lines:** {start}-{end}

**Description:**
{What the vulnerability is and how it could be exploited.}

**Code:**
```{language}
{quoted vulnerable code snippet}
```

**Impact:**
{What an attacker could achieve. Include healthcare/HIPAA implications where relevant.}

**Suggested Fix:**
```{language}
{remediation code example}
```

---

_(repeat for each finding)_

## Cross-Segment Flags

- `{file}:{lines}` — {description}
  **Needs:** {what the consolidator should check}
