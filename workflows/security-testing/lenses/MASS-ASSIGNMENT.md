# Mass Assignment

Detect Rails mass assignment vulnerabilities where user input can set unintended model attributes, including admin flags, roles, or foreign keys.

## What to Flag

### Overly Permissive Parameters
- `params.permit!` — permits everything
- `permit` with dangerous attributes: `role`, `admin`, `is_admin`, `permissions`, `organization_id`, `user_id`
- Long permit lists that may include sensitive attributes mixed in
- `assign_attributes` or `update` with unsanitized hashes

### Missing Strong Parameters
- `Model.create(params[:model])` without `.permit`
- `Model.update(params)` without filtering
- `Model.new(request.body)` in API controllers

### Nested Attributes
- `accepts_nested_attributes_for` without constraining which nested attributes are permitted
- Nested `permit` that allows setting foreign keys or IDs on associated records
- `_destroy` permitted without authorization check (allows deleting associations)

### Foreign Key Manipulation
- Permitting `*_id` fields that change ownership or association
- `tenant_id`, `organization_id`, `account_id` in permitted params
- `user_id` in permitted params (allows attributing actions to other users)

## Patterns

```ruby
# BAD: Permits everything
def user_params
  params.require(:user).permit!
end

# BAD: Includes dangerous attributes
def user_params
  params.require(:user).permit(:name, :email, :role, :admin)
end

# GOOD: Only safe attributes
def user_params
  params.require(:user).permit(:name, :email, :phone)
end
```

```ruby
# BAD: Foreign key in permitted params
def claim_params
  params.require(:claim).permit(:amount, :description, :organization_id, :user_id)
end

# GOOD: Set foreign keys from context
def create
  @claim = current_user.claims.build(claim_params)
  @claim.organization = current_organization
end

def claim_params
  params.require(:claim).permit(:amount, :description)
end
```

```ruby
# BAD: Nested attributes permit _destroy without auth
params.require(:patient).permit(:name, visits_attributes: [:id, :date, :notes, :_destroy])

# GOOD: Only if user is authorized to delete visits
params.require(:patient).permit(:name, visits_attributes: [:id, :date, :notes])
```

## Severity

- **CRITICAL**: `permit!` on user-facing endpoints, role/admin in permitted params
- **HIGH**: Foreign key manipulation (`organization_id`, `user_id`), `_destroy` without auth
- **MEDIUM**: Overly broad permit lists on sensitive models
- **LOW**: Unnecessary attributes permitted but not sensitive

## False Positives to Avoid

- Admin-only controllers with proper authorization (admin can set roles)
- Internal API endpoints not exposed to end users
- `permit!` in seeds, migrations, or rake tasks
- Factory/test code
