# React Performance Reviewer

Detect React performance issues including unnecessary re-renders, missing keys, and object creation in render.

## What to Flag

### Missing Keys
- List items without `key` prop
- Using array index as key when list order changes
- Non-unique keys across siblings

### Objects/Functions Created in Render
- Inline objects as props: `style={{ color: 'red' }}`
- Inline functions as props: `onClick={() => doThing()}`
- Array/object literals in JSX that create new references each render

### Unnecessary Re-renders
- Parent re-render causing all children to re-render
- Missing `memo()` on expensive pure components
- Context value changing reference unnecessarily

### Expensive Computations
- Heavy calculations in render without useMemo
- Filtering/sorting large lists on every render

## Patterns

```jsx
// BAD: New object every render
<Child style={{ color: 'red' }} />

// GOOD: Stable reference
const style = { color: 'red' }  // outside component
<Child style={style} />
```

```jsx
// BAD: No key on list items
{items.map(item => <li>{item.name}</li>)}

// GOOD: Unique stable key
{items.map(item => <li key={item.id}>{item.name}</li>)}
```

```jsx
// BAD: Index as key with reorderable list
{items.map((item, i) => <li key={i}>{item.name}</li>)}

// GOOD: Unique ID as key
{items.map(item => <li key={item.id}>{item.name}</li>)}
```

```jsx
// BAD: Inline function recreated each render
<Button onClick={() => handleClick(id)} />

// GOOD (if child is memoized): useCallback
const handleClickMemo = useCallback(() => handleClick(id), [id])
<Button onClick={handleClickMemo} />
```

## When Performance Optimization Matters

Only flag when:
- Child components are memoized (otherwise new reference doesn't matter)
- Lists are large (100+ items)
- Computations are expensive (measured, not assumed)
- Re-renders are causing visible lag

## Severity

- **CRITICAL**: Missing keys causing incorrect rendering/state
- **HIGH**: Expensive re-renders causing visible lag
- **MEDIUM**: Unnecessary renders, could be optimized

## False Positives to Avoid

- Inline functions when child isn't memoized (no benefit to extracting)
- Small lists where optimization adds complexity without benefit
- useMemo/useCallback without measured need (premature optimization)
- Object props that are stable due to parent memoization
