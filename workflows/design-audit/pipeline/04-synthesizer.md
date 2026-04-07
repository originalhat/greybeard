# Phase 4: Synthesizer

- **Role:** Design Spec Author
- **Model:** Opus
- **Input:** `../greybeard-data/output/design-audit/{repo}/inventory.md` + `../greybeard-data/output/design-audit/{repo}/findings.md` + `../greybeard-data/sources/{repo}/`
- **Output:** `../greybeard-data/output/design-audit/{repo}/design-spec.md` + `../greybeard-data/output/design-audit/{repo}/.design-state.json`

## Mission

Produce the living design specification — the canonical document that describes the actual design system in use. This is the artifact that code reviewers reference via the `DESIGN-CONSISTENCY-REVIEWER` lens. It must be accurate, actionable, and standalone.

## Process

### 1. Identify the Design System

From the inventory, determine what the *intended* design system is:
- **Explicit tokens:** CSS custom properties, Tailwind config, theme file, SCSS variables
- **Implicit patterns:** No formal system, but consistent values emerge from usage
- **Library-based:** MUI theme, Chakra theme, etc.
- **None:** No discernible system — values are ad hoc

Document the system type and where it lives. This frames the entire spec.

### 2. Document Tokens

For each design dimension, synthesize the inventory into a spec:

**Colors:** Group by role (primary, secondary, neutral, semantic). For each token: the canonical value, where defined, usage count, known violations (from findings).

**Typography:** Build the type scale from inventory data. For each step: token name, size, weight, line-height, usage context. Note font families and their roles.

**Spacing:** Build the spacing scale. For each step: token name, value, common usage context.

**Breakpoints:** List all defined breakpoints with their purpose.

If no formal tokens exist, document the *de facto* patterns: "The most common blue is #2563eb (used 14 times) — effectively the primary color, though not defined as a token."

### 3. Document Component Patterns

For each significant UI component pattern found in the inventory:
- **Canonical implementation:** The primary/shared version (file:line)
- **Variants:** What variants exist and their purposes
- **Props/Interface:** Key props and their conventions
- **Usage count:** How many times it appears
- **Known inconsistencies:** Linked to findings

### 4. Document Conventions

Synthesize implicit conventions from the codebase:
- **CSS methodology:** How styles are organized and scoped
- **File organization:** Where styles live relative to components
- **Responsive approach:** Mobile-first vs desktop-first, how breakpoints are applied
- **Naming:** Class naming patterns, variable naming patterns

### 5. Incorporate Findings

Thread findings into the relevant sections:
- Each token section should note its violations inline
- The "Known Inconsistencies" section provides a summary view
- Link back to `findings.md` for full details

### 6. Write Reviewer Checklist

Produce the "For Code Reviewers" section — a concise checklist that someone can scan in 30 seconds to know what to check when reviewing UI changes. This is what the `DESIGN-CONSISTENCY-REVIEWER` lens operationalizes.

## Output Format

Follow `templates/design-spec.md` exactly.

## State File

Write `.design-state.json`:

```json
{
  "repo": "{repo_name}",
  "last_audited_sha": "{sha}",
  "last_audited_at": "{ISO8601 timestamp}",
  "findings_summary": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  },
  "pages_screenshotted": 0,
  "mode": "full | static-only",
  "notes": "Full audit with visual capture"
}
```

## Catch-Up Mode

When running incrementally:
1. Read the existing `design-spec.md`
2. Update only sections affected by changed inventory data and new/resolved findings
3. Move newly resolved findings to the "Resolved" section with date and reference
4. Add new findings to "Known Inconsistencies"
5. Update the "Change Log" with what changed and when
6. Update `.design-state.json`

## Rules

- **The spec must be standalone.** A developer should be able to read it without the inventory or findings and understand the design system.
- **Every token/pattern must have code references.** file:line for where it's defined.
- **Document what IS, not what SHOULD BE.** If there's no token system, say so. Don't invent an ideal system.
- **Findings must be actionable.** Each inconsistency should have a clear path to resolution.
- **Be honest about gaps.** If the system is partial or inconsistent, say so clearly.
- **Tone:** Declarative, precise, grounded in code. "The primary color is #2563eb, defined in tokens.css:12" not "it appears the primary color might be blue."
