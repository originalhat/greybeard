# TypeScript Defensive Code Reviewer

Identify unnecessary defensive code where types already guarantee safety.

## What to Flag

### Unnecessary Null Checks
- Optional chaining (`?.`) on required properties
- Nullish coalescing (`??`) on non-optional fields
- Explicit null/undefined checks when type excludes them
- Default values for required parameters

### Redundant Type Checks
- `typeof` checks when type is already known
- `instanceof` checks on typed parameters
- Existence checks guaranteed by types

### Over-Defensive Patterns
- Defensive array fallbacks on required arrays: `arr || []`
- Default objects on required properties
- Copying readonly data unnecessarily

## Patterns

```typescript
interface User {
  name: string      // Required
  email: string     // Required
  tags: string[]    // Required array
}

// BAD: Unnecessary defensive code
function processUser(user: User) {
  const name = user.name ?? 'unknown'     // name can't be null
  const tags = user.tags || []            // tags can't be null
  if (user.email !== undefined) { }       // email is required
}

// GOOD: Trust the types
function processUser(user: User) {
  const name = user.name
  const tags = user.tags
  sendEmail(user.email)
}
```

```typescript
interface Config {
  timeout: number   // Required
}

// BAD: Optional chaining on required
function init(config: Config) {
  const timeout = config?.timeout ?? 5000
}

// GOOD: Direct access
function init(config: Config) {
  const timeout = config.timeout
}
```

```typescript
// BAD: Redundant typeof
function process(count: number) {
  if (typeof count === 'number') {  // Always true!
    return count * 2
  }
}

// GOOD: Trust the type
function process(count: number) {
  return count * 2
}
```

## When Defensive Code IS Appropriate

- External API responses (types may not match reality)
- User input before validation
- Data from localStorage/sessionStorage
- Third-party library data
- Legacy code migration

## Severity

- **HIGH**: Significant defensive code that clutters logic
- **MEDIUM**: Moderate unnecessary checks
- **LOW**: Minor defensive patterns

## False Positives to Avoid

- Defensive code for external data sources
- Backwards compatibility requirements
- Library code where callers might misuse types
- Types that should be optional but aren't yet
