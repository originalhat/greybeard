# Embedded Integration Security Reviewer

Detect insecure embedding of third-party apps and insecure handoff of credentials to them — iframe sandboxing, permissions policy, and short-lived tokens leaking through URLs, the DOM, or the `Referer` header.

Applies whenever a diff embeds an external app (iframe, popup) or mints/passes a token to launch one (SSO, JWE/JWT launch URLs).

## What to Flag

### iframe Embedding (frontend)
- `<iframe>` with **no `sandbox` attribute** — grants full privileges to embedded content. Add `sandbox` and whitelist only what's needed (e.g. `allow-scripts allow-same-origin allow-forms`).
- `allow` (Permissions-Policy) granting capabilities the embed does not use — `payment`, `publickey-credentials-get`, `camera`, `microphone`, `geolocation`. Grant the minimum.
- Missing `referrerpolicy="no-referrer"` on an iframe/link whose URL carries a token.
- Trusting `postMessage` from the frame without checking `event.origin`.

### Credential in the URL
- A token, JWE/JWT, or secret placed in a **URL** (launch URL, query string, redirect target). URLs land in browser history, server logs, and the `Referer` header sent to the next hop.
- The page serving such a URL missing `Referrer-Policy: no-referrer` (or `same-origin`) — the token leaks to third parties via `Referer`.
- Prefer a POST handoff (hidden form + `ref`) over embedding the token in the DOM or a GET URL.

### Credential in the DOM / logs
- Auth token rendered into the DOM (`src`, `value`, data attribute, inline script) where extensions, XSS, or DOM scraping can read it.
- Analytics/logging/error reporting capturing a **full URL or DOM node** that contains a token — confirm the token is stripped before capture.

### Handoff-Token Replay (backend)
- A launch/handoff token without **single-use enforcement**: no `jti` tracked as consumed (nonce), or no short expiry (`exp`). A token in a URL that can be replayed is a standing credential.
- Missing audience (`aud`)/issuer (`iss`) validation on the receiving side.

## Patterns

```tsx
// BAD: full-privilege iframe, over-broad allow, token in src (DOM + Referer leak)
<iframe src={`${fabricUrl}?token=${jwe}`} allow="payment; publickey-credentials-get" />

// GOOD: sandboxed, minimal capabilities, no referrer, token POSTed not in URL
<iframe
  ref={frameRef}
  sandbox="allow-scripts allow-same-origin allow-forms"
  referrerpolicy="no-referrer"
/>
// submit a hidden form POST to the frame; the token never enters the URL or the DOM src
```

```ruby
# BAD: long-lived, replayable launch token embedded in a URL
def launch_url
  "#{base}?token=#{jwe}"   # no jti, no short exp; page has no Referrer-Policy
end

# GOOD: single-use, short-lived; page sends Referrer-Policy: no-referrer
payload = { sub: patient_id, jti: SecureRandom.uuid, exp: 2.minutes.from_now.to_i, aud: FABRIC_AUD }
# receiver records jti as consumed on first use; rejects replays and expired tokens
```

## Severity

- **CRITICAL**: Replayable credential in a URL, or token leaked to a third party via `Referer` — standing account takeover.
- **HIGH**: Un-sandboxed iframe of third-party content; token readable from the DOM.
- **MEDIUM**: Over-broad `allow`/permissions; token captured in logs/analytics.

## False Positives to Avoid

- iframes embedding **first-party, same-origin** content you fully control.
- Opaque, already-single-use tokens (e.g. an authorization code) with a receiver that enforces one-time use.
- URLs that carry only non-secret identifiers, not credentials.
- `sandbox`/`allow` intentionally broad with a documented reason for a trusted partner.
