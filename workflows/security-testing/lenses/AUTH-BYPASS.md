# Authentication Bypass

Detect flaws that allow attackers to authenticate as another user or bypass authentication entirely.

## What to Flag

### Missing Authentication
- Endpoints without auth middleware/before_action
- `skip_before_action :authenticate_user!` without justification
- API endpoints accessible without tokens
- WebSocket connections without auth handshake

### JWT/Token Flaws
- Missing signature verification
- `none` algorithm accepted
- Missing expiry validation (`exp` claim)
- Symmetric key weakness (short/predictable secrets)
- Token not invalidated on logout or password change
- Refresh token rotation not enforced

### Session Fixation
- Session ID not regenerated after login (`reset_session` missing)
- Session token accepted from URL parameters
- Session created before authentication completes

### Password Reset Flaws
- Predictable reset tokens (sequential, timestamp-based)
- Reset tokens with no expiry or long expiry
- Token not invalidated after use
- User enumeration via reset flow (different responses for valid/invalid emails)

### OAuth/SSO Issues
- Missing `state` parameter validation (CSRF in OAuth)
- Open redirect in callback URLs
- Token exchange without origin verification

## Patterns

```ruby
# BAD: Skipping auth without scoping
class ApiController < ApplicationController
  skip_before_action :authenticate_user!
end

# GOOD: Skip only for specific public actions
class ApiController < ApplicationController
  skip_before_action :authenticate_user!, only: [:health_check]
end
```

```ruby
# BAD: No session regeneration after login
def create
  user = User.authenticate(params[:email], params[:password])
  session[:user_id] = user.id
end

# GOOD: Regenerate session
def create
  user = User.authenticate(params[:email], params[:password])
  reset_session
  session[:user_id] = user.id
end
```

## Severity

- **CRITICAL**: Complete auth bypass, session fixation in auth flow
- **HIGH**: JWT algorithm confusion, predictable reset tokens
- **MEDIUM**: Missing session regeneration, long-lived tokens
- **LOW**: User enumeration, verbose auth error messages

## False Positives to Avoid

- Intentionally public endpoints (health checks, login, signup, public API docs)
- Auth inherited from parent controller/middleware
- Internal service-to-service calls with separate auth
- Background jobs running as system user
