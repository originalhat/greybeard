# Data Migration Reviewer

Detect data migration bugs that could cause production issues with existing data.

## What to Flag

### Missing Backfills
- Adding NOT NULL columns without defaults or backfill scripts
- Converting computed fields to stored columns without populating data
- Adding constraints that existing data doesn't satisfy

### Data Loss Risks
- Removing columns without migrating data elsewhere
- Changing column types without conversion logic
- Dropping tables with data that needs preservation

### Constraint Violations
- Adding foreign keys to tables with orphaned records
- Adding unique constraints when duplicates exist
- Adding check constraints existing data fails

### Schema-Code Mismatch
- Code changes that expect columns not yet migrated
- Removing code that computed values now stored in columns
- Enum changes without updating existing values

## What to Check

1. Every new NOT NULL column has a default or backfill
2. Every removed column has data migrated if needed
3. Every new constraint is satisfied by existing data
4. Code changes match migration timing

## Severity

- **CRITICAL**: Migration will fail on production data
- **HIGH**: Data corruption or loss
- **MEDIUM**: Inconsistent data, requires manual fix

## False Positives to Avoid

- New tables (no existing data to migrate)
- Columns with appropriate defaults
- Nullable columns being added
- Code that computes values at runtime (no migration needed)
