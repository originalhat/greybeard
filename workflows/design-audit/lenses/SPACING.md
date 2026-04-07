# Spacing Consistency

Detect off-scale spacing values, inconsistent gap usage, mixed units, and layout hacks via negative margins.

## What to Flag

### Scale Violations
- Margin/padding values outside the spacing scale (e.g., `7px` on a 4px-based scale)
- One-off gap values in flex/grid layouts
- Inconsistent spacing for similar elements (cards with `16px` padding in one place, `20px` in another)

### Token Violations
- Hardcoded spacing when CSS variables or utility classes exist
- Inline style spacing bypassing the system
- Magic number spacing with no clear relationship to the scale

### Unit Inconsistency
- Mixed px/rem/em for the same type of spacing without clear convention
- Viewport units (vw/vh) for element spacing (usually a smell)

### Layout Hacks
- Negative margins used to correct alignment (symptom of upstream spacing issue)
- Spacing via empty elements or `<br>` tags
- `!important` on spacing properties to override cascade issues

## Patterns

```css
/* BAD: Off-scale arbitrary value */
.card { padding: 13px 17px; }

/* GOOD: Scale-aligned token */
.card { padding: var(--space-3) var(--space-4); }
```

```jsx
// BAD: Inline spacing hack
<div style={{ marginTop: -8, marginLeft: 3 }}>

// GOOD: Utility class from spacing scale
<div className="mt-2 ml-1">
```

```css
/* BAD: Inconsistent gaps in similar contexts */
.card-grid { gap: 16px; }
.user-grid { gap: 20px; }

/* GOOD: Consistent gap from scale */
.card-grid { gap: var(--space-4); }
.user-grid { gap: var(--space-4); }
```

## Severity

- **HIGH**: Spacing inconsistency causing visible layout misalignment
- **MEDIUM**: Off-scale values, hardcoded when tokens exist
- **LOW**: Minor unit inconsistency, cosmetic drift

## False Positives to Avoid

- Sub-pixel adjustments for optical alignment (icon centering, border compensation)
- Animation/transition offsets
- Third-party component overrides requiring specific values
- Pixel-perfect alignment with external assets (images, SVGs)
