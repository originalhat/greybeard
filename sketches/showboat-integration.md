# Showboat Integration for Review Feedback Loop

## Overview

Extend the code review workflow to capture verification decisions in a structured,
analyzable format using Showboat as the documentation backbone.

## Proposed CLI: `review-capture`

Wrapper/extension that adds structured decision capture to Showboat documents.

### Commands

```bash
# Start a review session (wraps showboat init)
review-capture start --repo myapp --pr 142 --branch feature/oauth

# Record a module's findings (auto-generated from review output)
review-capture flag \
  --module "SQL-INJECTION" \
  --file "src/db/queries.py" \
  --line 47 \
  --severity high \
  --summary "User input passed directly to query string"

# Human/agent makes a decision on a flagged issue
review-capture decide \
  --issue 1 \
  --verdict false-positive \
  --reason "Input validated by sanitize_input() at line 32" \
  --evidence "grep shows all callers go through validation layer"

# Or for a true positive
review-capture decide \
  --issue 2 \
  --verdict true-positive \
  --fix-suggested "Use parameterized query instead" \
  --fix-applied true

# Finalize the review
review-capture finish --summary "3 issues flagged, 1 true positive fixed"
```

### Verdict Types

| Verdict | Meaning | Module Impact |
|---------|---------|---------------|
| `true-positive` | Real issue, should be flagged | Reinforces module rule |
| `false-positive` | Not an issue, shouldn't flag | Module may be too aggressive |
| `true-negative-missed` | Real issue module missed | Module needs expansion |
| `wont-fix` | Real issue but acceptable | Context-specific, maybe add exception pattern |
| `needs-context` | Can't determine without more info | Module might need better context gathering |

## Data Structure

Each review session produces a Showboat markdown doc + structured sidecar:

### Showboat Document (human-readable)

```markdown
# PR Review: myapp #142

## Flagged Issues

### Issue 1: SQL-INJECTION (HIGH)
**File:** src/db/queries.py:47
**Finding:** User input passed directly to query string

**Decision:** FALSE-POSITIVE
**Reason:** Input validated by sanitize_input() at line 32
**Evidence:**
\`\`\`bash
$ grep -n "sanitize_input" src/db/queries.py
32:    cleaned = sanitize_input(user_query)
47:    cursor.execute(f"SELECT * FROM {cleaned}")
\`\`\`

---

### Issue 2: ...
```

### Structured Sidecar (machine-readable)

```json
{
  "review_id": "myapp-pr-142-2024-01-15",
  "repo": "myapp",
  "pr": 142,
  "branch": "feature/oauth",
  "reviewer": "claude",
  "timestamp": "2024-01-15T10:30:00Z",
  "issues": [
    {
      "id": 1,
      "module": "SQL-INJECTION",
      "file": "src/db/queries.py",
      "line": 47,
      "severity": "high",
      "summary": "User input passed directly to query string",
      "verdict": "false-positive",
      "reason": "Input validated by sanitize_input() at line 32",
      "evidence_commands": ["grep -n 'sanitize_input' src/db/queries.py"],
      "time_to_decide": "45s"
    }
  ],
  "summary": {
    "total_flagged": 3,
    "true_positives": 1,
    "false_positives": 2,
    "fixes_applied": 1
  }
}
```

## Analysis Layer

Aggregate sidecar data across reviews to generate insights:

```bash
# See false positive rate by module
review-analyze fp-rate --module SQL-INJECTION
# Output: SQL-INJECTION: 34% false positive rate (89/262 flags)

# Find common false positive patterns
review-analyze fp-patterns --module SQL-INJECTION
# Output:
#   - "sanitize_input" in call chain: 23 occurrences
#   - ORM parameterization: 18 occurrences
#   - Test file (non-prod): 12 occurrences

# Suggest module refinements
review-analyze suggest --module SQL-INJECTION
# Output:
#   Suggested additions to SQL-INJECTION.md:
#   - Add exception: "Skip if sanitize_input() called on input"
#   - Add exception: "Skip if file path contains /test/"

# Overall module health
review-analyze dashboard
# Output:
#   Module              | Flags | TP Rate | Avg Decision Time
#   --------------------|-------|---------|------------------
#   SQL-INJECTION       |   262 |   66%   | 38s
#   XSS-VULNERABILITIES |   184 |   81%   | 22s
#   ERROR-HANDLING      |   445 |   43%   | 55s  ← needs tuning
```

## Integration with Existing Workflow

### Current Flow (from CLAUDE.md)
1. Provide branch to review
2. Check out branch
3. Compare diff against origin/main
4. Evaluate in parallel using modules
5. Create final report
6. Fact-check issues in repo
7. Cross-repo analysis if needed
8. Final summary with PASS/FAIL per module

### Enhanced Flow
1. `review-capture start` - Initialize session
2. Check out branch
3. Compare diff against origin/main
4. Evaluate in parallel using modules
5. **For each flagged issue:** `review-capture flag` - Record finding
6. Fact-check issues in repo
7. **For each verified issue:** `review-capture decide` - Record verdict with evidence
8. Cross-repo analysis if needed
9. `review-capture finish` - Generate report + sidecar
10. **Periodic:** `review-analyze` - Refine modules based on accumulated data

## Module Auto-Refinement

With enough data, generate suggested patches to modules:

```markdown
<!-- AUTO-GENERATED SUGGESTION based on 23 false positives -->
<!-- Review and manually approve before committing -->

## Exceptions

Skip flagging if:
- Input passes through `sanitize_input()`, `escape_sql()`, or `parameterize()`
- File is in test directory (`**/test/**`, `**/*_test.py`)
- Using ORM methods: `.filter()`, `.get()`, `.objects.raw()` with params
```

## Open Questions

1. **Storage:** SQLite local? Cloud for team aggregation?
2. **Showboat integration:** Fork/extend vs. wrapper that calls showboat?
3. **Evidence capture:** How much context to auto-capture vs. manual?
4. **Reviewer attribution:** Track who made decisions for calibration?
5. **Confidence scoring:** Should modules output confidence levels to prioritize verification?
