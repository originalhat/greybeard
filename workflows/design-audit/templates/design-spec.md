# Design Specification: {repo}

- **Last updated:** {date}
- **Initial audit:** {date}
- **Status:** draft | current | stale
- **Open inconsistencies:** {N} — see [findings.md](findings.md)

## Design System Overview

{Framework, CSS approach, component library, token system summary. 2-4 sentences describing the overall design architecture and how styles are managed in this codebase.}

## Color Palette

### Primary

| Token | Value | Usage Count | Notes |
|-------|-------|-------------|-------|
| {--color-primary} | {#2563eb} | {14} | {Buttons, links, active states} |

### Secondary

| Token | Value | Usage Count | Notes |
|-------|-------|-------------|-------|

### Neutral

| Token | Value | Usage Count | Notes |
|-------|-------|-------------|-------|

### Semantic

| Token | Value | Usage Count | Purpose |
|-------|-------|-------------|---------|
| {--color-error} | {#dc2626} | {8} | {Error messages, destructive actions} |
| {--color-success} | {#16a34a} | {5} | {Success confirmations} |

### Known Violations

| Value | Should Be | Occurrences | Locations |
|-------|-----------|-------------|-----------|
| {#333} | {--color-neutral-900} | {7} | {See findings F-003} |

## Typography Scale

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| {--text-xs} | {12px} | {400} | {1.5} | {Captions, labels} |
| {--text-sm} | {14px} | {400} | {1.5} | {Body secondary, form fields} |
| {--text-base} | {16px} | {400} | {1.5} | {Body primary} |
| {--text-lg} | {18px} | {600} | {1.4} | {Section headers} |
| {--text-xl} | {24px} | {700} | {1.3} | {Page headers} |

### Font Families

| Role | Family | Fallback Stack |
|------|--------|---------------|
| {Primary} | {Inter} | {system-ui, -apple-system, sans-serif} |
| {Monospace} | {JetBrains Mono} | {Menlo, Consolas, monospace} |

### Known Violations

{Off-scale sizes, rogue families — linked to findings}

## Spacing Scale

| Token | Value | Common Usage |
|-------|-------|-------------|
| {--space-1} | {4px} | {Tight gaps, icon padding} |
| {--space-2} | {8px} | {Inline spacing, small gaps} |
| {--space-3} | {12px} | {Form field gaps} |
| {--space-4} | {16px} | {Card padding, section gaps} |
| {--space-6} | {24px} | {Section margins} |
| {--space-8} | {32px} | {Page section spacing} |

### Known Violations

{Off-scale values — linked to findings}

## Breakpoints

| Name | Value | Purpose |
|------|-------|---------|
| {sm} | {640px} | {Mobile landscape} |
| {md} | {768px} | {Tablet portrait} |
| {lg} | {1024px} | {Tablet landscape / small desktop} |
| {xl} | {1280px} | {Desktop} |

## Component Patterns

### Buttons

- **Canonical implementation:** {src/components/Button.tsx}
- **Variants:** {primary, secondary, ghost, destructive}
- **Props:** {variant, size, disabled, loading, onClick, children}
- **Usage count:** {34}
- **Known inconsistencies:** {2 instances of custom button divs — see findings}

### Cards

{Same structure}

### Forms / Inputs

{Same structure}

### Modals / Dialogs

{Same structure}

### Navigation

{Same structure}

{Add sections for each significant component pattern found}

## Conventions

### CSS Methodology
{How styles are organized — CSS modules, Tailwind utility-first, BEM, styled-components, etc.}

### File Organization
{Where styles live relative to components — co-located, centralized, hybrid}

### Responsive Approach
{Mobile-first vs desktop-first, how breakpoints are used, which components are responsive}

### Naming
{Class naming conventions, CSS variable naming patterns, component naming}

## For Code Reviewers

Quick-reference checklist when reviewing UI changes against this spec:

- [ ] New colors use tokens from the Color Palette section (no hardcoded hex/rgb)
- [ ] Font sizes and weights are from the Typography Scale
- [ ] Spacing values align with the Spacing Scale
- [ ] Breakpoints match the defined set (no hardcoded media queries)
- [ ] New components follow the prop conventions of existing Component Patterns
- [ ] No duplicate implementation of an existing shared component
- [ ] Responsive behavior tested at defined breakpoints

## Known Inconsistencies

{Summary of open findings from findings.md, grouped by theme}

| Theme | Count | Severity Range | Details |
|-------|-------|---------------|---------|
| {Hardcoded colors} | {7} | {HIGH} | {findings.md F-003, F-007} |

## Resolved

{Previously flagged inconsistencies that have been fixed}

| Issue | Resolved In | Date |
|-------|-------------|------|
| {Duplicate card components unified} | {PR #142} | {date} |

## Change Log

| Date | Change | Author |
|------|--------|--------|
| {date} | {Initial audit} | {Design Audit Agent} |
