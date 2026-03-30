# Domain Knowledge Reviewer

Ensure code changes align with extracted domain knowledge: ubiquitous language, business rules, and domain boundaries.

**Prerequisite:** Extracted knowledge must exist at `workflows/knowledge-extraction/output/{repo}/`

## What to Check

### 1. Ubiquitous Language Alignment

Check new/changed identifiers against `ubiquitous-language.md`:

- **Conflicting terms**: New variable/function/class names that use a term differently than documented
- **Deprecated terms**: Using terms marked as deprecated instead of their replacements
- **Missing context**: Introducing domain terms without following established naming patterns
- **Abbreviation drift**: Using abbreviations inconsistently with the documented list

### 2. Business Rule Compliance

Check changes against `domains/*.md` business rules:

- **Rule contradictions**: Logic that violates a `HIGH` confidence documented rule
- **Threshold changes**: Modifying magic numbers that are documented as product decisions
- **Missing guards**: Removing or bypassing documented constraints
- **Undocumented exceptions**: Adding special cases not reflected in domain docs

### 3. Domain Boundary Respect

Check that changes respect documented boundaries:

- **Cross-domain reach**: Code in one domain directly manipulating another domain's data
- **Boundary violations**: Bypassing documented integration points
- **Ownership confusion**: Adding logic that belongs to a different domain per docs

## Patterns

```typescript
// Domain knowledge says: "Member" is the term, not "User" or "Patient"
// BAD: Conflicting terminology
const getUserEligibility = (userId: string) => { ... }

// GOOD: Aligned with ubiquitous language
const getMemberEligibility = (memberId: string) => { ... }
```

```ruby
# Domain docs say: Trial period is 14 days (HIGH confidence, product decision)
# BAD: Changing without checking docs
TRIAL_DAYS = 30  # "increased for better conversion"

# GOOD: If changing, update domain docs and get product sign-off
TRIAL_DAYS = 14  # See domain docs: billing/trial-period rule
```

## Severity

- **CRITICAL**: Contradicts HIGH confidence business rule
- **HIGH**: Uses deprecated term or violates domain boundary
- **MEDIUM**: Terminology drift or inconsistent naming

## How to Evaluate

1. Load `ubiquitous-language.md` for the repo
2. Load relevant `domains/*.md` based on files changed
3. For each new/changed identifier, check terminology alignment
4. For logic changes, check against documented business rules
5. For cross-file changes, verify domain boundaries are respected

## False Positives to Avoid

- Code predates the knowledge extraction (legacy naming is acceptable context)
- Domain docs are marked `draft` or `LOW` confidence (flag for review, not failure)
- Technical terms vs domain terms (e.g., `userId` as a database column is fine)
- The change intentionally updates a rule (should update docs too, but not a code issue)

## When Knowledge Is Missing

If no extracted knowledge exists for the repo:
- Skip this lens
- Note in review: "Domain knowledge not yet extracted for this repo"

If knowledge exists but is stale:
- Apply lens but note staleness
- Consider triggering re-extraction for changed domains
