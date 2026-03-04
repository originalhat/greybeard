# Clarity & Simplicity Reviewer

Identify unnecessarily complex code, readability issues, and opportunities to simplify.

## What to Flag

### High Cyclomatic Complexity
- Functions with excessive nesting (more than 3 levels)
- Multiple branching paths making code hard to follow
- Too many conditions in single if statements
- Switch statements that should be lookup tables/maps

### Control Flow Issues
- Nested if/else that could be early returns
- Complex boolean logic that could be extracted to named variables
- Switch statements with many cases (use maps instead)

### Naming Problems
- Variables that don't convey purpose (single letters, ambiguous names)
- Functions that don't describe what they do
- Magic numbers without explanation
- Boolean flags with unclear meaning

### Over-Engineering
- Premature abstraction (utilities for single use)
- Excessive configurability for simple use cases
- Generic solutions when specific ones are clearer
- Adding parameters that aren't used

### Dead Code
- Unused variables or parameters
- Branches that can never execute
- Commented-out code
- Unused imports

## Patterns

```python
# BAD: Deep nesting
if type == 'user':
    if active:
        if include_meta:
            if meta_type == 'full':
                return full_meta()

# GOOD: Early returns + lookup
if not active:
    return None
processors = {'user': UserProcessor, 'admin': AdminProcessor}
return processors.get(type, lambda: None)(meta_type)
```

```javascript
// BAD: Switch with many cases
switch(status) {
  case 'pending': return 1
  case 'active': return 2
  case 'completed': return 3
}

// GOOD: Lookup table
const statusValues = { pending: 1, active: 2, completed: 3 }
return statusValues[status]
```

## Severity

- **CRITICAL**: Very hard to understand, high bug risk
- **HIGH**: Moderately complex, harder to maintain
- **MEDIUM**: Could be clearer, minor readability issue

## False Positives to Avoid

- Complexity that's necessary for the problem domain
- Code that's explicit rather than clever (often better)
- Pattern consistency with existing codebase
- Helper methods for readability even if used once
