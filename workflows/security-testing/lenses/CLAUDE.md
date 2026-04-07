# Security Lenses

Focused vulnerability detection criteria for whole-repo security scanning. Each lens targets a single vulnerability category.

## Conventions

Each lens:
- Focuses on a **single vulnerability category**
- Is **under 100 lines** for quick skimmability
- Contains: purpose, what to flag, patterns (BAD vs GOOD), severity guidance, false positives to avoid
- Includes **framework-specific patterns** where applicable (Rails, React, mobile)

## Available Lenses

| Category | Lenses |
|----------|--------|
| OWASP Core | INJECTION, XSS, AUTH-BYPASS, AUTHZ-ESCALATION, SSRF, MASS-ASSIGNMENT, INSECURE-DESERIALIZATION, FILE-UPLOAD |
| Healthcare | PHI-EXPOSURE, HIPAA-COMPLIANCE |
| Crypto | CRYPTOGRAPHY |
| Session & API | SESSION-MANAGEMENT, API-SECURITY |
| Supply Chain | DEPENDENCY-VULNS |
| Ops & Config | LOGGING-MONITORING, INFRASTRUCTURE-CONFIG |
| Mobile | MOBILE-SECURITY |

## Difference from Code Review Lenses

Code review lenses (`workflows/code-review/lenses/`) evaluate branch diffs — they catch new issues being introduced. Security testing lenses scan entire codebases — they find existing vulnerabilities regardless of when they were introduced. Security testing lenses go deeper on each category and include more framework-specific patterns.

## Adding a New Lens

1. Create `{LENS-NAME}.md` in this directory
2. Keep it under 100 lines
3. Focus on a single vulnerability category
4. Include: what to flag, BAD vs GOOD patterns, severity, false positives
5. Update the table above
