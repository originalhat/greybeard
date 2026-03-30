# Accessibility Reviewer

Detect accessibility (a11y) issues that prevent users with disabilities from using the application.

## What to Flag

### Missing Alternative Text
- Images without `alt` attributes
- Decorative images not marked with `alt=""`
- Icons conveying meaning without labels
- Background images with informational content

### Semantic HTML Issues
- Using `<div>` or `<span>` for interactive elements (should be `<button>`, `<a>`)
- Missing heading hierarchy (`<h1>` → `<h3>` skipping `<h2>`)
- Lists not using `<ul>`, `<ol>`, `<li>`
- Tables without proper headers (`<th>`, `scope`)
- Missing landmark elements (`<main>`, `<nav>`, `<header>`)

### Keyboard Navigation
- Click handlers without keyboard equivalents
- `onClick` without `onKeyDown`/`onKeyUp`
- Non-focusable interactive elements (missing `tabIndex`)
- Focus traps without escape
- Removing focus outlines without alternative

### ARIA Misuse
- ARIA attributes on elements that don't need them
- `aria-label` on non-interactive elements
- Missing `aria-expanded`, `aria-selected` on dynamic components
- `role` that conflicts with native semantics
- Missing live regions for dynamic content (`aria-live`)

### Form Accessibility
- Inputs without associated `<label>` (or `aria-label`)
- Missing error announcements for screen readers
- Required fields not indicated accessibly
- Form validation errors not linked to inputs

### Color and Contrast
- Information conveyed only through color
- Low contrast text (check against WCAG guidelines)
- Focus states relying only on color change

## Patterns

```jsx
// BAD: Div as button
<div onClick={handleClick}>Submit</div>

// GOOD: Semantic button
<button onClick={handleClick}>Submit</button>
```

```jsx
// BAD: Image without alt
<img src="chart.png" />

// GOOD: Descriptive alt
<img src="chart.png" alt="Sales increased 25% in Q4" />

// GOOD: Decorative image
<img src="decoration.png" alt="" />
```

```jsx
// BAD: Click without keyboard support
<div onClick={toggle} className="toggle">

// GOOD: Keyboard accessible
<button onClick={toggle} aria-expanded={isOpen}>
```

```jsx
// BAD: Input without label
<input type="email" placeholder="Email" />

// GOOD: Properly labeled
<label htmlFor="email">Email</label>
<input id="email" type="email" />
```

## Severity

- **CRITICAL**: Completely inaccessible (no keyboard access, missing form labels)
- **HIGH**: Major barriers (missing alt text on important images, broken focus)
- **MEDIUM**: Usability issues (suboptimal ARIA, heading hierarchy)

## False Positives to Avoid

- Decorative images correctly using `alt=""`
- ARIA on custom components that need it
- Third-party components with their own a11y handling
- CSS-hidden elements not needing a11y attributes
