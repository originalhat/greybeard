# Color Consistency

Detect palette drift, hardcoded values bypassing tokens, near-duplicate colors, and semantic color misuse.

## What to Flag

### Token Violations
- Hardcoded hex/rgb/hsl values when CSS variables or design tokens exist
- Colors defined in component files instead of the token system
- Inline style colors bypassing the theme

### Palette Drift
- Near-duplicate colors (e.g., `#333` and `#343434`, `#2563eb` and `#2564ec`)
- Colors not present in any defined palette or theme
- Gradual accumulation of one-off brand color variations

### Semantic Misuse
- Error/danger color used for non-error purposes
- Success color used outside success contexts
- Interactive color (links/buttons) used on non-interactive elements

### Opacity/Alpha
- Inconsistent opacity values for similar treatments (overlays, disabled states)
- Hardcoded rgba when a token with alpha channel exists

## Patterns

```css
/* BAD: Hardcoded color in component */
.card-header { background: #2563eb; }

/* GOOD: Token reference */
.card-header { background: var(--color-primary); }
```

```jsx
// BAD: Inline color bypassing theme
<div style={{ color: '#666' }}>

// GOOD: Theme reference
<div className="text-gray-500">
```

```scss
// BAD: Near-duplicate colors across files
$blue-primary: #2563eb;   // buttons.scss
$brand-blue: #2564ec;     // header.scss

// GOOD: Single source of truth
@use 'tokens' as t;
color: t.$color-primary;
```

## Severity

- **CRITICAL**: Semantic color misuse that breaks UX meaning (error color for info)
- **HIGH**: Hardcoded values when a token system exists
- **MEDIUM**: Near-duplicate colors, palette drift, inconsistent opacity

## False Positives to Avoid

- Third-party library overrides (sometimes hardcoded colors are necessary)
- SVG internal fill/stroke colors (often self-contained)
- One-off brand assets (logos, illustrations)
- Dark/light mode intentional variations
- Syntax highlighting or code display themes
