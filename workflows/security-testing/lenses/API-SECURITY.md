# API Security

Detect API-layer vulnerabilities including missing rate limiting, verbose errors, input validation gaps, and data exposure.

## What to Flag

### Rate Limiting
- Authentication endpoints without rate limiting (login, password reset, MFA)
- PHI access endpoints without rate limiting
- API endpoints allowing unlimited requests (data exfiltration via enumeration)
- Missing account lockout after failed login attempts

### Error Disclosure
- Stack traces returned in API responses
- SQL error messages exposed to clients
- Internal file paths in error responses
- Framework/library version information in headers or errors
- Different error formats for valid vs. invalid resources (enumeration)

### Input Validation
- Missing length limits on string inputs (buffer/storage abuse)
- No format validation on structured fields (email, phone, dates)
- Integer overflow potential on numeric inputs
- Missing pagination limits — unbounded `limit` or `per_page` parameters
- Array/batch endpoints with no maximum size

### Data Exposure
- API responses including fields not needed by the client
- Sensitive fields in list/index endpoints (should only be in detail view)
- Internal IDs, timestamps, or metadata leaking implementation details
- GraphQL introspection enabled in production
- GraphQL queries without depth/complexity limits

## Patterns

```ruby
# BAD: Verbose error response
rescue => e
  render json: { error: e.message, backtrace: e.backtrace }, status: 500
end

# GOOD: Generic error response
rescue => e
  Rails.logger.error(e.full_message)
  render json: { error: "Internal server error" }, status: 500
end
```

```ruby
# BAD: No pagination limit
def index
  @records = Record.limit(params[:limit])  # Client can request limit=999999
end

# GOOD: Capped pagination
def index
  limit = [params.fetch(:limit, 25).to_i, 100].min
  @records = Record.limit(limit)
end
```

```ruby
# BAD: Different responses reveal resource existence
# Returns 403 for existing resource, 404 for non-existing
def show
  record = Record.find(params[:id])  # raises 404 if not found
  authorize record                    # raises 403 if not authorized
end

# GOOD: Consistent response
def show
  record = current_user.accessible_records.find_by(id: params[:id])
  return head :not_found unless record
  render json: record
end
```

## Severity

- **CRITICAL**: No rate limiting on auth endpoints, stack traces in production
- **HIGH**: Unbounded queries enabling data exfiltration, verbose errors with internal paths
- **MEDIUM**: Missing input length limits, GraphQL introspection in production
- **LOW**: Over-exposed fields in responses, missing version headers

## False Positives to Avoid

- Rate limiting handled at infrastructure level (nginx, API gateway, WAF)
- Error formatting middleware that strips details in production
- Pagination enforced by framework defaults or base controller
- GraphQL introspection disabled via middleware/configuration
