# Ubiquitous Language: [Repo Name]

**Last updated:** [date]
**Status:** `draft` | `sme-reviewed` | `current`

---

## Overview

This glossary captures the domain-specific vocabulary used in this codebase. Terms here may differ from their generic meanings or from how other repos use them.

---

## Terms

### [Term]
**Also known as:** [aliases, abbreviations, or legacy names]
**Category:** [entity | process | state | role | event | concept]

**Definition:**
[What this term means in this codebase. Be precise—this is the authoritative definition.]

**Used in:**
- [file/path.ts] — [brief context]
- [another/file.rb] — [brief context]

**Related terms:**
- [OtherTerm] — [relationship: parent, child, triggers, depends on, etc.]

**Watch out for:**
[Common confusions, naming quirks, or historical baggage]

**Cross-repo notes:**
[How this term maps to other repos. Same name but different meaning? Different name for same concept?]

---

[repeat Term block for each term]

---

## Naming Patterns

[Document any consistent naming conventions in the codebase:]

| Pattern | Meaning | Example |
|---------|---------|---------|
| `*_at` | Timestamp field | `created_at`, `enrolled_at` |
| `is_*` | Boolean flag | `is_active`, `is_eligible` |
| `*Service` | Service object | `ClaimsService`, `EnrollmentService` |

---

## Abbreviations

| Abbrev | Full Term | Notes |
|--------|-----------|-------|
| [abbr] | [full term] | [context if needed] |

---

## Cross-Repo Term Alignment

| This Repo | Other Repo | Notes |
|-----------|------------|-------|
| [term here] | [equivalent in other repo] | [same/different meaning, mapping notes] |

---

## Deprecated Terms

| Term | Replaced By | When | Notes |
|------|-------------|------|-------|
| [old term] | [new term] | [date/version] | [why changed, where old term might still appear] |

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| [date] | Initial extraction from codebase | Agent |
