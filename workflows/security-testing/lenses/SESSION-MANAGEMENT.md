# Session Management

Detect session handling weaknesses including fixation, expiry issues, cookie misconfiguration, and concurrent session risks.

## What to Flag

### Session Fixation
- Session not regenerated after authentication (`reset_session` missing after login)
- Session ID accepted from URL parameters or POST body
- Session created before user authenticates and carried forward

### Cookie Security
- Missing `Secure` flag (cookies sent over HTTP)
- Missing `HttpOnly` flag (cookies accessible to JavaScript)
- Missing `SameSite` attribute (CSRF via cookies)
- Overly broad cookie domain or path scope
- Sensitive data stored directly in cookies (not just session ID)

### Session Lifetime
- No session timeout configured
- Excessively long session lifetime (>8 hours for general use, >30 minutes for PHI access)
- No idle timeout (session lives forever if tab stays open)
- Session not invalidated on logout (`session.destroy` / `reset_session` missing)
- Session not invalidated on password change

### Concurrent Sessions
- No limit on concurrent sessions per user
- No mechanism to view/revoke active sessions
- Session tokens not invalidated when user account is disabled/locked

### Token Storage
- Session tokens in localStorage (accessible to XSS)
- Tokens in URL parameters (logged, cached, shared via referrer)
- Tokens in browser history

## Patterns

```ruby
# BAD: No session invalidation on logout
def destroy
  redirect_to root_path
end

# GOOD: Destroy session
def destroy
  reset_session
  redirect_to root_path
end
```

```ruby
# BAD: No session timeout
Rails.application.config.session_store :cookie_store

# GOOD: Configured timeout
Rails.application.config.session_store :cookie_store,
  expire_after: 30.minutes,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

```javascript
// BAD: Token in localStorage
localStorage.setItem('authToken', response.token)

// GOOD: HttpOnly cookie set by server (not accessible to JS)
// Token managed server-side via Set-Cookie header
```

## Severity

- **CRITICAL**: Session fixation, no session invalidation on logout
- **HIGH**: Missing Secure/HttpOnly flags in production, no session timeout for PHI
- **MEDIUM**: Overly long session lifetime, no idle timeout
- **LOW**: Missing SameSite attribute, no concurrent session controls

## False Positives to Avoid

- Development-only cookie configuration (`if Rails.env.development?`)
- Session stores that handle expiry server-side (Redis with TTL)
- SPA token refresh mechanisms that rotate tokens regularly
- Remember-me tokens with separate security controls
