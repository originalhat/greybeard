# Lenses

Technical review criteria that are **generalized** and broadly applicable. Not specific to any repo, team, or business.

Each lens:
- Focuses on a single area of concern
- Is under 100 lines for quick skimmability
- Contains patterns, anti-patterns, and what to look for

## Available Lenses

| Category | Lenses |
|----------|--------|
| Security | AUTH-SECURITY, PHI-PII-HIPAA |
| React | REACT-HOOKS, REACT-PERFORMANCE, REACT-STATE |
| TypeScript | TYPESCRIPT-TYPE-SAFETY, TYPESCRIPT-DEFENSIVE-CODE |
| Data | N-PLUS-ONE-QUERY, DATA-MIGRATION, IDEMPOTENCY |
| Architecture | SEPARATION-OF-CONCERNS, EXTENSIBILITY, CLARITY-SIMPLICITY |
| Infrastructure | CRON, JOB-CONFIGURATION, WEBSOCKET-BROADCAST |
| Compatibility | API-BREAKING-CHANGES, BROWSER-COMPATIBILITY, CLIENT-SERVER-DATA-CONTRACT, CROSS-ORIGIN-REQUEST |
| Quality | TESTING-COVERAGE, ACCESSIBILITY |
| Domain | DOMAIN-KNOWLEDGE (requires extracted knowledge) |

## Adding a New Lens

1. Create `{LENS-NAME}-REVIEWER.md`
2. Keep it under 100 lines
3. Focus on a single concern
4. Include: what to check, common issues, and examples
