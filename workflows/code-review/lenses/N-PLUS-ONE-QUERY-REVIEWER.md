# N+1 Query Reviewer

Detect N+1 query patterns that cause excessive database queries and performance degradation.

## What is N+1?

An N+1 query occurs when code:
1. Fetches N records from the database (1 query)
2. Then makes 1 additional query for each record (N queries)
3. Results in N+1 total queries instead of 1-2 optimized queries

## What to Flag

### Loops with Database Access
- Iterating over records and accessing associations
- Calling `.count()`, `.exists()` on associations in loops
- Accessing nested relationships without eager loading
- Making queries inside `.each`, `.map`, `.filter` blocks

### Missing Eager Loading
- Collections accessed without `includes`, `preload`, `prefetch_related`
- Serializers/JSON builders that access associations
- Template rendering that iterates and accesses relations

### Removed Optimizations
- Eager loading removed during refactoring
- Optimized query replaced with naive version

### No-op and Invalid Eager Loads
- **Unassigned/unchained `.preload` / `.includes` / `.eager_load`** — these return a new relation; if the result isn't assigned back or chained into the query that's actually iterated, the call is a **silent no-op** and associations still lazy-load N+1 style. `tasks = rel; tasks.preload(:foo)` loads nothing — it must be `tasks = rel.preload(:foo)`.
- **Assigning back a previously-discarded eager-load list is not a mechanical cleanup.** The moment a dormant no-op list starts executing, *every* clause in it runs for the first time. Re-verify each named association actually exists and is preloadable — a clause that was invalid all along (see below) will only raise *now*. Treat this like adding new code, not tidying a variable. (See `OPPORTUNISTIC-REFACTOR`.)
- **ActiveStorage attachments are not preloadable by their attachment name.** `has_one_attached :file` / `has_many_attached :files` generate `file_attachment` + `file_blob` (or `files_attachments`) associations — there is no association literally named `file`. `preload(record: :file)` raises `ActiveRecord::AssociationNotFoundError`. Eager-load attachments with `with_attached_file` (scope) or `preload(record: { file_attachment: :blob })`.
- **Prefer a single shared eager-load list over hand-maintained duplicates.** When one action uses a canonical list (a presenter's `.preload`, a scope) and a sibling action hand-rolls its own, the bespoke copy drifts and is where invalid/incomplete clauses hide. Consolidate onto the shared source.

## Patterns

```ruby
# BAD: N+1 - one query per user for posts
users.each { |u| puts u.posts.count }

# GOOD: Eager load
User.includes(:posts).each { |u| puts u.posts.count }
```

```python
# BAD: N+1 queries
for user in users:
    print(user.profile.bio)

# GOOD: Select related
for user in User.objects.select_related('profile'):
    print(user.profile.bio)
```

```ruby
# BAD: no-op — result discarded, still N+1. And `patient_files: :file` is an
# invalid preload (`file` is a has_one_attached, not an association) that will
# raise AssociationNotFoundError the instant this list actually executes.
tasks = record.tasks.order(:created_at)
tasks.preload(:assigned_to, patient_files: :file)   # <- return value dropped

# GOOD: assigned back, shared list, attachments preloaded correctly
tasks = record.tasks.order(:created_at).preload(Presenters::Task.preload)
# ...where the shared list uses: patient_files: { file_attachment: :blob }
```

## Severity

- **CRITICAL**: Endpoint will timeout with production data
- **HIGH**: Slow but works, affects paginated results
- **MEDIUM**: Slow only with large datasets

## False Positives to Avoid

- Single-record fetches (not iterating)
- Loops that don't access the database
- Already-optimized queries with proper eager loading
- Accessing attributes already loaded (not associations)
