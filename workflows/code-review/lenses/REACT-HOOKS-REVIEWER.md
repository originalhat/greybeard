# React Hooks Reviewer

Detect hooks misuse including dependency issues, missing cleanup, and rules of hooks violations.

## What to Flag

### useEffect Dependencies
- Missing dependencies that should trigger re-runs
- Empty `[]` when effect depends on props/state
- Dependencies that cause infinite loops
- Object/array dependencies created in render (always new reference)

### Missing Cleanup
- Timers (`setTimeout`, `setInterval`) not cleared
- Event listeners not removed
- Subscriptions not unsubscribed
- Async operations that update state after unmount

### Rules of Hooks Violations
- Hooks called conditionally (`if (condition) { useState() }`)
- Hooks called in loops
- Hooks called in nested functions
- Hooks not at top level of component

### useCallback/useMemo Misuse
- Missing dependencies in useCallback/useMemo
- Unnecessary memoization (no expensive computation, no memo'd child)
- Dependencies that change every render, defeating the purpose

### useRef Misuse
- Using useRef for state that should trigger re-renders
- Accessing ref.current during render (anti-pattern)

## Patterns

```jsx
// BAD: Missing dependency
useEffect(() => {
  fetchUser(userId)
}, [])  // userId missing - won't refetch when it changes

// GOOD: Correct dependencies
useEffect(() => {
  fetchUser(userId)
}, [userId])
```

```jsx
// BAD: Missing cleanup
useEffect(() => {
  const timer = setInterval(tick, 1000)
  // No cleanup - timer keeps running after unmount
}, [])

// GOOD: Cleanup function
useEffect(() => {
  const timer = setInterval(tick, 1000)
  return () => clearInterval(timer)
}, [])
```

```jsx
// BAD: Conditional hook
if (isLoggedIn) {
  useEffect(() => { ... })  // Violates rules of hooks
}
```

## Severity

- **CRITICAL**: Memory leaks, stale closures causing bugs
- **HIGH**: Missing dependencies cause stale data
- **MEDIUM**: Unnecessary memoization, suboptimal patterns

## False Positives to Avoid

- Empty deps `[]` when effect truly should run once on mount
- Intentionally omitted dependencies with eslint-disable comment
- useRef for DOM refs or mutable values that don't need re-render
