# Layout Consistency

Detect breakpoint drift, missing responsive behavior, z-index wars, and inconsistent container/grid patterns.

## What to Flag

### Breakpoints
- Hardcoded media query values that don't match defined breakpoints
- Inconsistent breakpoint values across files (e.g., `768px` vs `769px`)
- Missing breakpoints for key viewport ranges

### Responsive Behavior
- Components that don't adapt at standard breakpoints
- Fixed widths/heights that should be responsive
- Overflow/scrolling issues at narrower viewports (visible in screenshots)
- Content truncation without indication

### Z-Index
- Z-index values outside a defined scale
- Escalating z-index wars (`z-index: 9999`, `z-index: 99999`)
- No z-index system (random values scattered across files)

### Containers and Grid
- Inconsistent max-width values for page containers
- Mixed grid approaches without clear convention
- Inconsistent column counts at the same breakpoint

## Patterns

```css
/* BAD: Hardcoded breakpoint mismatched with system */
@media (min-width: 769px) { ... }

/* GOOD: Shared breakpoint variable */
@media (min-width: $breakpoint-md) { ... }
```

```css
/* BAD: Z-index war */
.modal { z-index: 99999; }
.tooltip { z-index: 999999; }

/* GOOD: Z-index scale */
.modal { z-index: var(--z-modal); }
.tooltip { z-index: var(--z-tooltip); }
```

```css
/* BAD: Inconsistent containers */
.page-a { max-width: 1200px; }
.page-b { max-width: 1280px; }

/* GOOD: Shared container */
.page-a, .page-b { max-width: var(--container-lg); }
```

## Severity

- **CRITICAL**: Broken layout at standard viewports (visible in screenshots)
- **HIGH**: Inconsistent breakpoints, z-index chaos
- **MEDIUM**: Mixed grid approaches, inconsistent container widths

## False Positives to Avoid

- Intentionally fixed-width elements (modals, tooltips, popovers)
- Print-specific layouts
- Third-party component layout overrides
- Aspect-ratio-locked media elements
