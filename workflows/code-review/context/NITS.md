# Code Review Checklist (Nits)

A checklist of common issues to look for during PR reviews.

## Rails Controllers

- [ ] **Avoid unnecessary transactions** - Don't wrap single `save` calls in transactions. Rails handles this automatically. Only use transactions when multiple records need to be saved atomically.

- [ ] **Rescue `RecordInvalid` when using bang methods** - If using `update!` or `save!`, add `rescue ActiveRecord::RecordInvalid` to return proper 422 responses instead of 500 errors.

- [ ] **Return 204 No Content for destroy actions** - DELETE endpoints should return `head :no_content` rather than rendering the deleted resource.

## Rails Models / Presenters

- [ ] **Add explicit order when using `.first`** - When calling `.first` on associations, add `.order(...)` to ensure consistent results. Without ordering, the database may return records unpredictably.

## Migrations

- [ ] **Use appropriate column types** - Dates should be `date` type, not `string`. Timestamps should be `datetime`. Don't store structured data as strings when a proper type exists.

## React Components

- [ ] **Use guard clauses instead of type assertions** - Prefer `if (!value) return;` over `value as Type`. This is safer and removes the need for type casts.

- [ ] **Memoize expensive calculations** - Use `useMemo` for calculations that depend on specific values and don't need to recompute on every render.

- [ ] **Consistent decimal places** - Ensure displayed numeric values use consistent precision throughout the UI (e.g., BMI should show 2 decimal places everywhere).

## React Testing

- [ ] **Use `userEvent` over `fireEvent`** - `userEvent` provides more realistic user interactions, simulating actual behavior like typing character by character and proper event sequences.

## API / Frontend Data Transformation

This codebase has automatic transformations between Rails and React that you need to be aware of:

### Key Transformation (snake_case → camelCase)

Rails presenters return **snake_case** keys, but `ApplicationController#render_json` automatically converts them to **camelCase** via `deep_transform_keys { |key| key.to_s.camelize(:lower) }`.

```ruby
# Presenter returns:
{ measured_at: "2024-02-25", blood_pressure: { systolic: 120 } }

# API response becomes:
{ "measuredAt": "2024-02-25", "bloodPressure": { "systolic": 120 } }
```

### Date/DateTime Transformation (string → DateTime)

The frontend `ajax.ts` module uses a `reviver` function (from `Types.ts`) that automatically converts date strings to Luxon `DateTime` objects for keys matching:
- `/.+At$/` (e.g., `measuredAt`, `createdAt`, `updatedAt`)
- `/.+Since$/`
- `/.+Date$/`

**The string must be in ISO format** for the reviver to recognize it:
- `"2024-02-25"` ✓ (matches `^\d{4}-\d{2}-\d{2}$`)
- `"2024-02-25T00:00:00Z"` ✓ (matches ISO 8601 with time)
- `"2024-02-25 00:00:00 -0600"` ✗ (Ruby's default `.to_s` - NOT recognized)

### In Presenters: Use `.iso8601` for dates

```ruby
# BAD - produces "2024-02-25 00:00:00 -0600" which won't be converted
measured_at: @vital.measured_at.to_s

# GOOD - produces "2024-02-25" which the reviver converts to DateTime
measured_at: @vital.measured_at.iso8601
```

### In Tests: Mock with camelCase keys and DateTime objects

Since the reviver runs on API responses, test mocks should use the **post-transformation** format:

```typescript
const mockVitals = [
  {
    id: 1,
    measuredAt: DateTime.fromISO("2024-02-20"),  // camelCase + DateTime
    bloodPressure: { systolic: 120, diastolic: 80 },
  },
];
```

## Domain-Specific

- [ ] **Use correct terminology** - Verify abbreviations and terms match industry standards (e.g., SBP/DBP for blood pressure, not SYS/DYS).
