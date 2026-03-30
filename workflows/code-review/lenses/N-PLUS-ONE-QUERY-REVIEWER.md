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

## Severity

- **CRITICAL**: Endpoint will timeout with production data
- **HIGH**: Slow but works, affects paginated results
- **MEDIUM**: Slow only with large datasets

## False Positives to Avoid

- Single-record fetches (not iterating)
- Loops that don't access the database
- Already-optimized queries with proper eager loading
- Accessing attributes already loaded (not associations)
