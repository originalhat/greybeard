# Component Consistency

Detect duplicate UI implementations, inconsistent component interfaces, and missing opportunities for shared components.

## What to Flag

### Duplicate Implementations
- Multiple components implementing the same UI pattern (e.g., 3 different card layouts)
- Feature-specific versions of components that exist in a shared library
- Copy-pasted component code with minor variations

### Interface Inconsistency
- Similar components with different prop names for the same concept (`isOpen` vs `open` vs `visible`)
- Inconsistent variant naming (`type="primary"` vs `variant="primary"` vs `color="primary"`)
- Missing standard props on components of the same type (some buttons have `disabled`, others don't)

### Visual Inconsistency
- Same component type rendered differently in different contexts (visible in screenshots)
- Buttons, inputs, cards, or modals that look different across pages
- Inconsistent icon sizing or treatment

### Missing Shared Components
- The same UI pattern appears 3+ times with inline implementation
- Raw HTML/JSX where a design system component exists
- Wrapper divs recreating what a layout component provides

## Patterns

```jsx
// BAD: Custom button when shared component exists
<div className="btn-custom" onClick={handler}>Save</div>

// GOOD: Shared component
<Button variant="primary" onClick={handler}>Save</Button>
```

```jsx
// BAD: Inconsistent interfaces
<Modal isOpen={show} />      // Component A
<Dialog visible={show} />    // Component B (same pattern)

// GOOD: Unified interface
<Modal open={show} />
```

```jsx
// BAD: Inline pattern repeated across features
<div className="rounded border p-4 shadow-sm">
  <h3>{title}</h3>
  <p>{description}</p>
</div>

// GOOD: Extracted shared component
<Card title={title} description={description} />
```

## Severity

- **HIGH**: Duplicate implementations creating maintenance burden (3+ copies)
- **MEDIUM**: Inconsistent prop interfaces, visual inconsistency across instances
- **LOW**: Minor variations, components that could potentially be shared

## False Positives to Avoid

- Intentionally specialized components (a chart card is different from a profile card)
- Components actively being extracted/refactored
- Third-party component wrappers that need different interfaces
- Prototypes or experimental features not yet standardized
