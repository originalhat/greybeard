# Typography Consistency

Detect font stack drift, off-scale sizes, inconsistent weights, and missing responsive type adjustments.

## What to Flag

### Font Family
- Font families not in the defined type stack
- Fallback stack inconsistencies across files
- Missing web font imports for referenced families

### Size Scale
- Font sizes outside the defined type scale (e.g., `13px` when scale is 12/14/16)
- Hardcoded sizes when tokens exist
- Pixel values when the convention is rem/em (or vice versa)

### Weight and Style
- Font weights not in the defined weight set
- Numeric weights inconsistent with named weights (`500` vs `medium`)
- Italic used inconsistently for similar contexts

### Line Height and Spacing
- Line heights that don't follow the scale
- Inconsistent letter-spacing values
- Text with no explicit line-height in dense layouts

### Responsive Type
- Missing responsive font-size adjustments at breakpoints
- Type that doesn't scale between mobile and desktop

## Patterns

```css
/* BAD: Off-scale size */
.subtitle { font-size: 13px; }

/* GOOD: Scale-aligned */
.subtitle { font-size: var(--text-sm); /* 14px */ }
```

```css
/* BAD: Inconsistent weight references */
.bold-text { font-weight: 700; }
.emphasis { font-weight: bold; }  /* same weight, different notation */

/* GOOD: Consistent token usage */
.bold-text { font-weight: var(--font-bold); }
```

```css
/* BAD: Rogue font family */
.special-heading { font-family: 'Playfair Display', serif; }

/* GOOD: From the type stack */
.special-heading { font-family: var(--font-display); }
```

## Severity

- **HIGH**: Unknown font family not in the type stack
- **MEDIUM**: Off-scale size or weight, hardcoded values when tokens exist
- **LOW**: Line-height drift, minor letter-spacing inconsistency

## False Positives to Avoid

- Code/monospace font contexts (editors, terminal displays)
- Third-party component styling that can't use tokens
- Print stylesheets with different type requirements
- Email templates with inline style requirements
