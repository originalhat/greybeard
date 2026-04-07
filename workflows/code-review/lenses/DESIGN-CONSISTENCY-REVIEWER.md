# Design Consistency Reviewer

Ensure code changes align with the documented design specification: color tokens, typography scale, spacing system, layout conventions, and component patterns.

**Prerequisite:** Design audit output must exist at `../greybeard-data/output/design-audit/{repo}/`

## What to Check

### 1. Token Compliance

Check new/changed styles against `design-spec.md` tokens:

- **Hardcoded values**: New hex/rgb colors, pixel font-sizes, or spacing values when tokens exist
- **Off-scale values**: Values not present in the documented scale (e.g., `13px` font-size on a 12/14/16 scale)
- **New tokens**: Adding tokens without updating the design spec
- **Bypassed system**: Inline styles or `!important` overriding the token system

### 2. Component Consistency

Check new/changed components against documented patterns:

- **Duplicate implementations**: Building a new button/card/modal when a shared one exists
- **Interface drift**: Using different prop names than the documented convention
- **Visual deviation**: Styling that doesn't match the established look of that component type

### 3. Convention Adherence

Check that changes follow documented conventions:

- **CSS methodology**: Using a different styling approach than the codebase convention
- **Responsive approach**: Missing breakpoint handling or using wrong breakpoints
- **File organization**: Putting styles in unexpected locations

## Patterns

```css
/* BAD: Hardcoded color when token exists */
.alert-banner { background: #dc2626; }

/* GOOD: Token reference */
.alert-banner { background: var(--color-error); }
```

```jsx
// BAD: Custom card when shared component exists
<div className="rounded border p-4 shadow">
  <h3>{title}</h3>
</div>

// GOOD: Shared component
<Card title={title} />
```

```css
/* BAD: Off-scale spacing */
.section { padding: 13px 17px; }

/* GOOD: Scale-aligned */
.section { padding: var(--space-3) var(--space-4); }
```

## Severity

- **CRITICAL**: Changes that break layout at standard viewports or misuse semantic colors
- **HIGH**: Hardcoded values when tokens exist, duplicate component implementations
- **MEDIUM**: Off-scale values, minor convention drift, missing responsive handling

## How to Evaluate

1. Load `design-spec.md` for the repo
2. For each changed CSS/style file, check values against documented tokens and scales
3. For each new/changed component, check against documented component patterns
4. For convention changes, verify alignment with documented approach
5. Check the "For Code Reviewers" checklist in the design spec

## False Positives to Avoid

- Code that predates the design audit (legacy styling is acceptable context)
- Design spec is marked `draft` or `stale` (flag for review, not failure)
- Third-party component styling overrides (often necessary)
- Intentional design system evolution (should update spec too, but not a code issue)
- One-off overrides with clear justification in comments

## When Design Spec Is Missing

If no design audit output exists for the repo:
- Skip this lens
- Note in review: "Design audit not yet run for this repo"

If the spec exists but is stale (last audit > 3 months or many commits behind):
- Apply lens but note staleness
- Consider triggering a catch-up: `catch up design for {repo-name}`
