# Design Findings: {repo}

- **Date:** {date}
- **Agent:** Analyzer (Opus)
- **Repo SHA:** {sha}
- **Lenses applied:** COLOR, TYPOGRAPHY, SPACING, LAYOUT, COMPONENTS
- **Screenshots analyzed:** {N or "None — static analysis only"}
- **Mode:** {Full audit / Catch-up from {previous_sha}}

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {N} |
| HIGH | {N} |
| MEDIUM | {N} |
| LOW | {N} |

## Findings

### CRITICAL

#### {F-001}: {Title}

- **Severity:** CRITICAL
- **Confidence:** {CONFIRMED / LIKELY / POSSIBLE}
- **Lens:** {COLOR / TYPOGRAPHY / SPACING / LAYOUT / COMPONENTS}
- **File:** {file_path}
- **Lines:** {L100-L120}
- **Screenshot:** {page-desktop.png or "N/A"}

**Description:** {What the inconsistency is}

**Evidence:**
```{language}
{Code snippet showing the issue}
```
{If screenshot available: "Visual evidence: {screenshot reference} shows {what's visible}"}

**Impact:** {Why this matters — UX confusion, maintenance burden, accessibility}

**Suggested Fix:**
```{language}
{Code showing the fix}
```

---

### HIGH

{Same format as CRITICAL}

### MEDIUM

{Same format as CRITICAL}

### LOW

{Same format as CRITICAL}

## Cross-Lens Patterns

{Findings that span multiple lenses. E.g., "A set of 5 card components each have independent color, spacing, AND typography inconsistencies — suggesting they were built independently and should be unified into a shared component."}

## Positive Observations

{Design patterns done well. E.g., "The color token system is well-organized and covers 90% of color usage. Typography scale is consistent across all page headers."}

## Resolved

{For catch-up mode only. Previously flagged findings that are now fixed.}

| ID | Title | Resolved In | Date |
|----|-------|-------------|------|
| {F-001} | {Title} | {SHA or PR} | {date} |
