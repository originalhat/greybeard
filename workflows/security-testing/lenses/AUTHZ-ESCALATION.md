# Authorization & Privilege Escalation

Detect authorization failures where authenticated users can access resources or perform actions beyond their permitted scope.

## What to Flag

### Insecure Direct Object Reference (IDOR)
- Records fetched by ID without ownership check: `Model.find(params[:id])`
- Missing `current_user` scoping on queries
- Bulk endpoints returning unscoped results
- File/document access by path or ID without authorization

### Horizontal Escalation
- User A accessing User B's resources
- Missing tenant/organization isolation in multi-tenant systems
- Shared resource access without membership verification
- API responses leaking other users' data through associations

### Vertical Escalation
- Regular users accessing admin functionality
- Role checks that can be bypassed (client-side only, or missing on certain actions)
- Self-service role modification (user updating their own `role` or `admin` field)
- Missing permission checks on destructive operations (delete, bulk update)

### Multi-Tenant Isolation
- Queries not scoped to current organization/tenant
- Cross-tenant data leakage through shared caches or queues
- Missing tenant context in background jobs
- Default scopes that can be bypassed with `.unscoped`

## Patterns

```ruby
# BAD: IDOR — any authenticated user can access any record
def show
  @patient = Patient.find(params[:id])
end

# GOOD: Scoped to current user's organization
def show
  @patient = current_organization.patients.find(params[:id])
end
```

```ruby
# BAD: Missing authorization on destructive action
def destroy
  Claim.find(params[:id]).destroy
end

# GOOD: Policy-based authorization
def destroy
  claim = current_user.accessible_claims.find(params[:id])
  authorize claim, :destroy?
  claim.destroy
end
```

```ruby
# BAD: Bypassable tenant scope
Patient.unscoped.where(id: params[:ids])

# GOOD: Always enforce tenant scope
current_tenant.patients.where(id: params[:ids])
```

## Severity

- **CRITICAL**: PHI accessible across tenants, admin functions exposed to regular users
- **HIGH**: IDOR on sensitive records, missing tenant isolation
- **MEDIUM**: IDOR on non-sensitive data, incomplete permission checks
- **LOW**: Information disclosure through error messages revealing resource existence

## False Positives to Avoid

- System/admin contexts that legitimately access all records (background jobs, data migrations)
- Public resources intentionally accessible to all authenticated users
- Authorization handled by middleware or policy objects not visible in the controller
- Pundit/CanCanCan policies checked via `authorize` call (verify the policy exists)
