# Cross-Origin Request Reviewer

Detect mismatches between client-side cross-origin requests and server-side CORS/cookie configuration.

**Model tier: Haiku** - Pattern matching on config files and fetch options; no complex reasoning required.

## What to Flag

### Client-Side Credential Changes
- Adding `credentials: "include"` to fetch/XHR requests
- Switching from header-based auth to cookie-based auth
- Changing from same-origin to cross-origin API calls

### Missing Server CORS Configuration
- Cross-origin requests without server `credentials: true`
- `Access-Control-Allow-Origin: *` with credential requests (invalid)
- Missing preflight (`OPTIONS`) handling for custom headers

### Cookie Domain/Path Issues
- Cookies set on wrong domain for cross-subdomain sharing
- Missing `SameSite=None; Secure` for cross-site cookies
- `httpOnly` cookies expected by JS code

### Multi-Service Deployment Gaps
- Client changes without corresponding server changes
- CORS config in one environment but not others
- WebSocket origins not matching HTTP CORS origins

## Patterns

```typescript
// REQUIRES server-side credentials: true in CORS config
fetch(crossOriginUrl, {
  credentials: "include",  // <- Flag: verify server supports this
  headers: { "Content-Type": "application/json" }
})
```

```ruby
# BAD: Missing credentials support
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://app.example.com"
    resource '/api/*', headers: :any, methods: [:get, :post]
  end
end

# GOOD: Supports credentialed requests
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://app.example.com"
    resource '/api/*', headers: :any, methods: [:get, :post], credentials: true
  end
end
```

```ruby
# Cookie domain for cross-subdomain sharing
# app.example.com -> api.example.com
cookies[:token] = {
  value: token,
  domain: '.example.com',      # <- Leading dot for subdomains
  secure: true,
  same_site: :none,            # <- Required for cross-site
  httponly: true
}
```

## Cross-Service Checklist

When client adds `credentials: "include"`:
1. Server CORS has `credentials: true`
2. `Access-Control-Allow-Origin` is specific origin (not `*`)
3. Cookie domain covers both client and API domains
4. `SameSite` and `Secure` attributes are appropriate
5. WebSocket `allowed_request_origins` matches if applicable

## Severity

- **CRITICAL**: All API calls will fail silently in browser
- **HIGH**: Auth cookies won't be sent, causing 401s
- **MEDIUM**: Works in dev but fails in production (different domains)

## False Positives to Avoid

- Same-origin requests (no CORS needed)
- Server-to-server calls (not browser-based)
- Changes to non-credentialed requests
- Internal tooling on same domain
