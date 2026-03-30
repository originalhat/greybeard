# React State Reviewer

Detect state management issues including duplicated state, improper lifting, and data flow violations.

## What to Flag

### State Duplication
- Child copying props into state (gets stale when props change)
- Same data stored in multiple components
- Derived values stored in state (should compute in render)

### Data Flow Violations
- Props being mutated directly
- Child directly modifying parent state
- Bidirectional data binding patterns

### State Location Issues
- State too high (causes unnecessary re-renders)
- State too low (sibling components can't access)
- Local state when Context would reduce prop drilling

### Prop Drilling
- Props passed through 3+ intermediate components unchanged
- Many components just forwarding props
- Deeply nested prop chains

### Controlled vs Uncontrolled
- Mixing controlled and uncontrolled patterns on same input
- Switching between controlled/uncontrolled during lifecycle

### Fragmented Form State
- Multiple `useState` calls for related form fields that belong together
- Manual object reconstruction from separate state pieces
- Scattered reset logic across multiple state setters
- Passing reconstructed objects to comparison hooks/utilities

## Patterns

```jsx
// BAD: Derived state stored in useState
function User({ firstName, lastName }) {
  const [fullName, setFullName] = useState(`${firstName} ${lastName}`)
  // fullName gets stale when props change!
}

// GOOD: Compute in render
function User({ firstName, lastName }) {
  const fullName = `${firstName} ${lastName}`
}
```

```jsx
// BAD: Child duplicates parent state
function Child({ count }) {
  const [localCount, setLocalCount] = useState(count)
  // localCount diverges from parent's count
}

// GOOD: Single source of truth
function Child({ count, onChange }) {
  return <button onClick={() => onChange(count + 1)}>{count}</button>
}
```

```jsx
// BAD: Mutating props
function User({ user }) {
  user.name = 'changed'  // Never mutate props!
}
```

```jsx
// BAD: Fragmented form state - easy to miss field in reconstruction
const [name, setName] = useState("")
const [email, setEmail] = useState("")
const formData = { name, email }  // Must remember all fields!
const reset = () => { setName(""); setEmail("") }  // Scattered

// GOOD: Unified form state
const [formData, setFormData] = useState({ name: "", email: "" })
const setValue = (k, v) => setFormData(p => ({ ...p, [k]: v }))
const reset = () => setFormData({ name: "", email: "" })
```

## Severity

- **CRITICAL**: Data inconsistency, props mutation
- **HIGH**: Stale data from duplicated state, fragmented state causing missed fields
- **MEDIUM**: Prop drilling, suboptimal state location, scattered reset logic

## False Positives to Avoid

- Intentional local state for UI-only concerns
- Props used as initial value with `useState(prop)` when that's the intent
- Controlled components that properly sync state
- Context usage that appropriately reduces prop drilling
- Separate useState for truly independent fields (e.g., one controls visibility, another holds data)
