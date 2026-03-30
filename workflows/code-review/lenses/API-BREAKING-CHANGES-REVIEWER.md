# API Breaking Changes Reviewer

Detect breaking changes to API contracts that will cause client applications to fail.

## Breaking Changes

### Response Changes (Breaking)
- Removing or renaming fields in responses
- Changing field types (string → int, array → object)
- Changing response format or structure
- Removing HTTP headers clients depend on

### Request Changes (Breaking)
- Adding required parameters without defaults
- Renaming or removing parameters
- Changing parameter types
- Making optional parameters required

### Endpoint Changes (Breaking)
- Removing endpoints
- Changing HTTP methods or URL paths
- Changing status codes for existing scenarios

### Safe Changes (Non-Breaking)
- Adding new optional parameters
- Adding new fields to responses
- Adding new endpoints
- Making required parameters optional

## What to Flag

1. **Field removals/renames** in serializers, presenters, or JSON builders
2. **New required parameters** without default values
3. **Type changes** in response fields
4. **Endpoint deletions** or method changes
5. **Status code changes** that clients handle specifically

## Severity

- **CRITICAL**: Production clients will break immediately
- **HIGH**: Data loss or corruption possible
- **MEDIUM**: Degraded experience for some clients

## False Positives to Avoid

- Internal refactoring that doesn't change wire format
- Adding new endpoints or optional fields
- Changes to internal helper methods
- Test-only changes
