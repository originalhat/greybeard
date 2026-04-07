# Server-Side Request Forgery (SSRF)

Detect patterns where user-controlled input influences server-side HTTP requests, potentially allowing access to internal services or cloud metadata.

## What to Flag

### Direct SSRF
- User-supplied URLs passed to HTTP clients (`Net::HTTP`, `HTTParty`, `Faraday`, `RestClient`, `fetch`, `axios`)
- Webhook URLs accepted from users without validation
- URL parameters used in server-side redirects or fetches
- Image/file download from user-provided URLs

### URL Validation Bypass
- Allowlists checking only prefix/substring (bypassable with `attacker.com#allowed.com`)
- Missing validation of resolved IP (DNS rebinding)
- URL parsing inconsistencies between validator and HTTP client
- Redirect following that bypasses initial URL validation

### Internal Service Access
- Requests to cloud metadata endpoints (`169.254.169.254`, `metadata.google.internal`)
- Access to internal services via SSRF (localhost, private IP ranges)
- Internal API keys obtainable via metadata endpoints

### File Schemes
- `file://` protocol in URL handlers
- Accepting arbitrary URI schemes

## Patterns

```ruby
# BAD: User URL fetched directly
def fetch_avatar
  response = HTTParty.get(params[:avatar_url])
  save_avatar(response.body)
end

# GOOD: Validate URL, restrict to HTTPS, block private IPs
def fetch_avatar
  url = validate_external_url!(params[:avatar_url])  # raises on private IP, non-HTTPS
  response = HTTParty.get(url, follow_redirects: false)
  save_avatar(response.body)
end
```

```ruby
# BAD: Webhook URL without validation
WebhookService.post(organization.webhook_url, payload)

# GOOD: Validated webhook with allowlist
url = validate_webhook_url!(organization.webhook_url)
WebhookService.post(url, payload, timeout: 5)
```

## Severity

- **CRITICAL**: SSRF reaching cloud metadata or internal services with credentials
- **HIGH**: Unrestricted URL fetching with user input
- **MEDIUM**: SSRF with partial validation that may be bypassable
- **LOW**: SSRF limited to specific protocols or with network-level restrictions in place

## False Positives to Avoid

- URLs from admin-configured settings (trusted input, not user-supplied)
- Hardcoded URLs to known external services
- Internal service-to-service calls with no user input in the URL
- URL construction from validated, constrained components (e.g., `"https://api.example.com/#{model.id}"`)
