# PHI Exposure

Detect Protected Health Information leakage through logs, errors, caches, URLs, analytics, and other unintended channels. Goes deeper than the code-review PHI-PII-HIPAA lens — this scans the full codebase for exposure vectors.

## What to Flag

### Logging
- PHI fields in `Rails.logger`, `console.log`, `print`, `puts`
- PHI in structured logging (JSON payloads with patient data)
- Request/response logging that captures PHI in bodies
- Exception messages containing PHI (caught exceptions re-logged with context)

### Error Tracking
- PHI in Sentry/Rollbar/Bugsnag context, tags, or breadcrumbs
- Exception payloads that include patient records
- User context sent to error trackers containing PHI fields

### Caches & Queues
- PHI stored in Redis/Memcached without encryption or TTL
- PHI in Sidekiq/ActiveJob arguments (visible in job dashboards)
- PHI in ActionCable/WebSocket broadcast payloads
- Session stores containing PHI

### URLs & Parameters
- PHI in URL paths (`/patients/123/ssn/456-78-9012`)
- PHI in query parameters (visible in server logs, browser history, referrer headers)
- PHI in GET request parameters (should be POST)

### Client-Side
- PHI in browser localStorage/sessionStorage
- PHI in React state accessible via DevTools
- PHI in mobile AsyncStorage/SharedPreferences without encryption
- PHI in clipboard operations

### Analytics & Tracking
- PHI sent to analytics services (Mixpanel, Segment, Google Analytics)
- PHI in event properties or user traits
- PHI in A/B testing context

## Patterns

```ruby
# BAD: PHI in log message
Rails.logger.info("Processing claim for #{patient.name}, DOB: #{patient.date_of_birth}")

# GOOD: Reference by ID only
Rails.logger.info("Processing claim for patient_id=#{patient.id}")
```

```ruby
# BAD: PHI in Sidekiq job arguments
PatientNotificationJob.perform_async(patient.name, patient.email, patient.diagnosis)

# GOOD: Pass ID only, look up in job
PatientNotificationJob.perform_async(patient.id)
```

```ruby
# BAD: PHI in error tracker context
Sentry.set_context("patient", { name: patient.name, ssn: patient.ssn })

# GOOD: Non-PHI identifiers only
Sentry.set_context("patient", { id: patient.id })
```

```javascript
// BAD: PHI in localStorage
localStorage.setItem('currentPatient', JSON.stringify(patientRecord))

// GOOD: Store reference only, fetch from API
localStorage.setItem('currentPatientId', patientId)
```

## Severity

- **CRITICAL**: PHI in logs shipped to external services, PHI in analytics, SSN/diagnosis exposure
- **HIGH**: PHI in error tracking, PHI in URLs, PHI in job arguments visible in dashboards
- **MEDIUM**: PHI in application-level caches with TTL, PHI in session stores
- **LOW**: PHI in client-side state accessible only via DevTools in authenticated session

## False Positives to Avoid

- De-identified data (no PHI linkage per HIPAA Safe Harbor)
- Internal record IDs that don't map to individuals
- Encrypted fields being passed (not stored/logged plaintext)
- Test/seed data clearly marked as synthetic
- Authorized data exports with audit logging
