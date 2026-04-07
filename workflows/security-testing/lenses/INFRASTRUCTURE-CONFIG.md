# Infrastructure & Configuration

Detect security misconfigurations in deployment settings, server configuration, CORS policies, security headers, and environment management.

## What to Flag

### Debug & Development Mode
- `Rails.env` checks that could default to development behavior
- `DEBUG=true` or verbose mode in production configuration
- React DevTools, Redux DevTools enabled in production builds
- Detailed error pages enabled in production (e.g., `config.consider_all_requests_local = true`)

### CORS Misconfiguration
- `Access-Control-Allow-Origin: *` with credentials
- Wildcard origin with `Access-Control-Allow-Credentials: true`
- Origin reflection (echoing back the request Origin header without validation)
- Overly broad origin allowlists (e.g., `*.example.com` when only specific subdomains need access)

### Security Headers
- Missing `Content-Security-Policy` header
- Missing `Strict-Transport-Security` (HSTS) header
- Missing `X-Content-Type-Options: nosniff`
- Missing `X-Frame-Options` (clickjacking protection)
- Missing `Referrer-Policy` (leaking URLs to third parties)

### Default Credentials
- Default admin passwords in seed files or configuration
- Default database credentials in committed config
- Default API keys or tokens in configuration files

### Exposed Interfaces
- Admin panels accessible without IP restriction or VPN
- Database admin tools (phpMyAdmin, pgAdmin) exposed
- Monitoring endpoints (health checks) leaking system information
- Sidekiq/Resque web UI accessible without authentication

### Environment Management
- Production secrets in non-production config files
- Missing environment-specific security settings
- Shared credentials across environments
- `.env` files committed to version control

## Patterns

```ruby
# BAD: CORS allows all origins with credentials
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', credentials: true
  end
end

# GOOD: Specific origins
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://app.example.com', 'https://admin.example.com'
    resource '/api/*', credentials: true
  end
end
```

```ruby
# BAD: Detailed errors in production
# config/environments/production.rb
config.consider_all_requests_local = true

# GOOD: Generic errors in production
config.consider_all_requests_local = false
```

```yaml
# BAD: Default credentials in config
database:
  username: admin
  password: admin123

# GOOD: Environment variables
database:
  username: <%= ENV['DB_USERNAME'] %>
  password: <%= ENV['DB_PASSWORD'] %>
```

## Severity

- **CRITICAL**: CORS with wildcard + credentials, production secrets committed, exposed admin panels
- **HIGH**: Debug mode in production, default credentials, missing HSTS
- **MEDIUM**: Missing security headers, overly broad CORS, exposed monitoring
- **LOW**: Missing Referrer-Policy, verbose health checks

## False Positives to Avoid

- Security headers set at the reverse proxy/CDN level (nginx, CloudFront)
- CORS configuration that correctly restricts origins
- Development/test environment configuration files
- Health check endpoints intentionally public (verify they don't leak sensitive info)
