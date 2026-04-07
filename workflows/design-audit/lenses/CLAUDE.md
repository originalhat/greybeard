# Design Audit Lenses

Focused design consistency criteria for whole-repo design auditing. Each lens targets a single visual dimension.

These lenses are used by the **Analyzer** (Phase 3) to evaluate the inventory and screenshots. They are separate from code-review lenses.

## Conventions

Each lens:
- Focuses on a single design dimension
- Is under 100 lines for quick skimmability
- Contains: What to Flag, Patterns (BAD/GOOD), Severity, False Positives

## Available Lenses

| Lens | Focus |
|------|-------|
| COLOR | Palette consistency, token usage vs hardcoded, near-duplicates |
| TYPOGRAPHY | Font families, size scale, weights, line heights |
| SPACING | Spacing scale adherence, one-off values, mixed units |
| LAYOUT | Breakpoints, responsive behavior, z-index, containers |
| COMPONENTS | Duplicate implementations, inconsistent props, missing shared components |

## Adding a New Lens

1. Create `{LENS-NAME}.md`
2. Keep it under 100 lines
3. Focus on a single design dimension
4. Include: What to Flag, Patterns, Severity, False Positives
