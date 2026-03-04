# Auth Security Reviewer

Detect authentication and authorization vulnerabilities that could allow unauthorized access.

## What to Flag

### Missing Authentication
- New endpoints without auth checks
- Removed auth decorators/middleware
- Public routes that should be protected

### Missing Authorization
- Operations without permission checks
- Accessing other users' data without ownership validation
- Admin operations accessible to regular users
- Removed role/permission checks

### Insecure Direct Object Reference (IDOR)
- Fetching records by ID without checking ownership
- No scoping to current user
- Missing tenant/organization isolation

### Privilege Escalation
- Users able to modify their own roles/permissions
- Missing hierarchical permission checks
- Role changes without proper authorization

## Patterns

```ruby
# BAD: No ownership check (IDOR)
def show
  @record = Record.find(params[:id])  # Any user can access any record
end

# GOOD: Scoped to current user
def show
  @record = current_user.records.find(params[:id])
end
```

```python
# BAD: Missing auth decorator
@app.route('/api/admin/users')
def list_users():
    return User.all()

# GOOD: Auth required
@app.route('/api/admin/users')
@require_admin
def list_users():
    return User.all()
```

```javascript
// BAD: No auth middleware
app.delete('/api/users/:id', (req, res) => {
  User.delete(req.params.id)
})

// GOOD: Auth + authorization
app.delete('/api/users/:id', requireAuth, requireAdmin, (req, res) => {
  User.delete(req.params.id)
})
```

## Severity

- **CRITICAL**: Direct data breach, complete auth bypass
- **HIGH**: Privilege escalation, unauthorized data access
- **MEDIUM**: Information disclosure, weak controls

## False Positives to Avoid

- Internal helper methods not exposed to HTTP
- Intentionally public endpoints (login, signup, public APIs)
- Code inheriting auth from parent class/controller
- Background jobs running as system
