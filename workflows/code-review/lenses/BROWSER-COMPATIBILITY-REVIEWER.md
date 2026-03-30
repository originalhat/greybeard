# Browser Compatibility Reviewer

Detect code that relies on browser-specific behaviors, error messages, or APIs that function differently across browsers and devices.

## What to Flag

### Browser-Specific Error Messages
- Checking error messages by exact string (`error.message === "Failed to fetch"`)
- Relying on error names that vary by browser
- Parsing error stack traces (format differs per browser)

### Unreliable Browser APIs
- `navigator.onLine` (unreliable on many platforms)
- `navigator.connection` (limited support)
- `window.performance.memory` (Chrome-only)

### Event/Input Differences
- Touch events without pointer event fallback
- Clipboard API without fallback
- Keyboard event assumptions beyond common keys

### Storage and Date Quirks
- localStorage quota assumptions (varies 5-10MB)
- `Date.parse()` format assumptions
- Safari cookie/storage restrictions

## Patterns

```typescript
// BAD: Browser-specific error message
function isNetworkError(error: unknown): boolean {
  return error instanceof TypeError && error.message === "Failed to fetch"
}

// GOOD: Abstract at the source, throw custom error
async function fetchWithNetworkError(url: string) {
  try {
    return await fetch(url)
  } catch (e) {
    if (e instanceof TypeError) throw new NetworkError(e.message)
    throw e
  }
}
```

```typescript
// BAD: Relying solely on navigator.onLine
if (navigator.onLine) {
  submitForm()
}

// GOOD: Treat as hint, handle actual failures gracefully
try {
  await postData(data)
} catch (e) {
  if (e instanceof NetworkError) showOfflineUI()
}
```

```typescript
// BAD: Parsing error stacks
const line = error.stack.split('\n')[1].match(/:(\d+):/)[1]

// GOOD: Use error monitoring service for stack parsing
reportError(error)
```

## Key Question

Can this be abstracted at a lower level to be browser-agnostic?

## When Browser-Specific Code IS Appropriate

- Feature detection with graceful degradation
- Polyfills with proper capability checks
- Browser-specific workarounds with clear comments

## Severity

- **HIGH**: Core functionality breaks on supported browsers
- **MEDIUM**: Feature degradation without fallback
- **LOW**: Minor inconsistencies, cosmetic differences
