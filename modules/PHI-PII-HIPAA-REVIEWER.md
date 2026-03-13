# PHI/PII/HIPAA Reviewer

Detect improper handling of Protected Health Information (PHI), Personally Identifiable Information (PII), and HIPAA compliance violations.

## What to Flag

### Logging Sensitive Data
- Logging PHI/PII fields (SSN, DOB, diagnoses, medications, addresses)
- Debug statements containing patient/user data
- Error messages exposing sensitive information
- Request/response logging without redaction

### Improper Data Exposure
- API responses including unnecessary sensitive fields
- PHI/PII in URLs or query parameters
- Sensitive data in client-side state/storage
- Exposing full records when partial data suffices

### Inadequate Encryption
- Storing PHI/PII in plaintext
- Missing encryption at rest for sensitive fields
- Transmitting sensitive data without TLS
- Weak or deprecated encryption algorithms

### Missing Access Controls
- PHI accessible without role-based restrictions
- No audit logging for sensitive data access
- Missing "minimum necessary" data filtering
- Bulk data exports without authorization checks

### Data Retention Issues
- No expiration for sensitive data
- Missing data deletion capabilities
- Retaining PHI beyond required periods
- Backup/cache containing unmanaged PHI

## Patterns

```python
# BAD: Logging PHI
logger.info(f"Processing patient: {patient.name}, SSN: {patient.ssn}")

# GOOD: Redacted logging
logger.info(f"Processing patient_id: {patient.id}")
```

```javascript
// BAD: PHI in URL
fetch(`/api/patients?ssn=${ssn}&dob=${dob}`)

// GOOD: PHI in POST body over HTTPS
fetch('/api/patients/search', {
  method: 'POST',
  body: JSON.stringify({ ssn, dob })
})
```

```ruby
# BAD: Exposing full patient record
def show
  render json: @patient  # Includes SSN, diagnoses, etc.
end

# GOOD: Scoped response
def show
  render json: @patient.as_json(only: [:id, :name, :appointment_date])
end
```

```python
# BAD: Storing plaintext
patient.ssn = request.data['ssn']

# GOOD: Encrypted storage
patient.ssn_encrypted = encrypt(request.data['ssn'])
```

## Severity

- **CRITICAL**: PHI exposure, unencrypted transmission, logging SSN/diagnoses
- **HIGH**: Missing access controls, PHI in URLs, inadequate encryption
- **MEDIUM**: Excessive data in responses, missing audit trails

## False Positives to Avoid

- De-identified or anonymized data (no PHI linkage)
- Internal IDs that don't map to individuals
- Encrypted fields being processed (not stored/logged plaintext)
- Test/mock data clearly marked as synthetic
- Authorized data exports with proper audit logging
