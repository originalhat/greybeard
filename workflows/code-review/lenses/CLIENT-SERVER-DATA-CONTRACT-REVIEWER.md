# Client-Server Data Contract Reviewer

Detect mismatches between client-side types and server-side validation that can cause silent data corruption.

## What to Flag

### Loose Client Types
- Using `string` for dates, enums, or formatted values
- No branded/nominal types for format-specific strings
- Missing format documentation in type definitions

### Missing Server Validation
- Date/time fields without format validation
- Relying on ORM type coercion without explicit checks
- Enum fields accepting arbitrary strings
- Numeric fields without range validation at API boundary

### Silent Coercion Risks
- Rails/ActiveRecord auto-coercing invalid values to nil
- JSON parsers silently converting types
- Missing `before_type_cast` validation for format checks

### Contract Drift
- Client sends format A, server expects format B
- API documentation doesn't match actual validation
- Different date formats across endpoints

## Patterns

```typescript
// BAD: Loose client type
interface LabData {
  measured_at: string  // Could be anything!
}

// BETTER: Documented format
interface LabData {
  measured_at: string  // ISO 8601: YYYY-MM-DD
}

// BEST: Branded type (if tooling supports)
type ISODateString = string & { readonly brand: 'ISODate' }
```

```ruby
# BAD: Silent coercion - invalid dates become nil
validates :measured_at, presence: true  # Passes if coerced to nil!

# GOOD: Validate raw input format
validate :measured_at_is_valid_date

def measured_at_is_valid_date
  raw = measured_at_before_type_cast
  return if raw.blank? || raw.is_a?(Date)
  Date.strptime(raw.to_s, '%Y-%m-%d')
rescue ArgumentError
  errors.add(:measured_at, "must be YYYY-MM-DD format")
end
```

## What to Check

1. Every date field has server-side format validation
2. Client types document expected formats
3. Enum values validated against allowed list on server
4. API tests cover invalid format scenarios

## Severity

- **HIGH**: Silent data corruption from coercion
- **MEDIUM**: Missing validation that could accept bad data
- **LOW**: Loose types without format documentation

## False Positives to Avoid

- Internal APIs with trusted callers
- Fields where any string format is valid
- Explicit nil handling in business logic
