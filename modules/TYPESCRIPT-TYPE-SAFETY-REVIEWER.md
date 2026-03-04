# TypeScript Type Safety Reviewer

Identify missed opportunities to leverage the type system for better compile-time safety.

## What to Flag

### Weak Types
- Use of `any` type without justification
- Using `Object` or `{}` instead of specific types
- Implicit `any` from missing type annotations
- Overly broad `string` when literal unions would be better

### Missing Type Guards
- Type assertions (`as`) instead of proper type guards
- Missing exhaustiveness checks in switch statements
- No narrowing in conditional branches
- instanceof/typeof checks that could be type predicates

### Generic Issues
- Generics without constraints
- Lost type information in generic chains
- Missing type arguments

### Discriminated Unions
- Union types without discriminator field
- Related types that should share a discriminator
- Missing exhaustive handling of union cases

## Patterns

```typescript
// BAD: any type
function process(data: any): any {
  return data.value
}

// GOOD: Proper types
interface Data { value: string }
function process(data: Data): string {
  return data.value
}
```

```typescript
// BAD: String when literal union is better
function setStatus(status: string) { }
setStatus('typo')  // No error!

// GOOD: Literal union
type Status = 'pending' | 'active' | 'completed'
function setStatus(status: Status) { }
```

```typescript
// BAD: No exhaustiveness check
function getColor(status: Status): string {
  switch (status) {
    case 'pending': return 'yellow'
    case 'active': return 'green'
    // Missing 'completed'!
  }
}

// GOOD: Exhaustiveness check
function getColor(status: Status): string {
  switch (status) {
    case 'pending': return 'yellow'
    case 'active': return 'green'
    case 'completed': return 'blue'
    default:
      const _exhaustive: never = status
      return _exhaustive
  }
}
```

## Severity

- **HIGH**: Common code path with weak types, catches bugs early
- **MEDIUM**: API surface improvement, better IDE support
- **LOW**: Nice to have, improves expressiveness

## False Positives to Avoid

- Justified `any` for third-party libraries or truly dynamic data
- Type annotations that would be more verbose than helpful
- Matching existing codebase patterns
