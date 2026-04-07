# HIPAA Compliance

Detect gaps in HIPAA technical safeguard requirements. Focused on regulatory compliance controls — audit trails, access controls, encryption, and retention.

## What to Flag

### Audit Trail Gaps
- PHI read/write/delete operations without audit logging
- Missing `accessed_by`, `accessed_at` tracking on PHI records
- Audit logs that can be modified or deleted by application users
- No logging of failed access attempts to PHI

### Access Control Deficiencies
- PHI endpoints without role-based access control
- Missing "minimum necessary" data filtering — returning full records when partial data suffices
- No mechanism to restrict PHI access by role or relationship
- Bulk PHI export without authorization and audit

### Encryption Requirements
- PHI stored without encryption at rest (database fields, files, backups)
- Missing TLS enforcement on PHI transmission endpoints
- API endpoints accepting HTTP (not HTTPS) for PHI operations
- Weak encryption algorithms for PHI (DES, RC4, small key sizes)

### Session & Access Timeout
- No automatic session timeout for PHI-accessing sessions
- Excessively long session lifetimes (>30 minutes for PHI access)
- No re-authentication for sensitive PHI operations
- Missing idle timeout

### Data Integrity
- PHI records without versioning or change tracking
- No checksums or integrity verification on PHI data
- Missing validation on PHI data import/export

### Third-Party Integrations
- PHI sent to external services without BAA documentation
- Third-party SDKs with access to PHI data
- External APIs receiving PHI without encryption in transit

## Patterns

```ruby
# BAD: PHI access without audit trail
def show
  @patient = current_org.patients.find(params[:id])
  render json: @patient
end

# GOOD: Audit logged
def show
  @patient = current_org.patients.find(params[:id])
  AuditLog.record(user: current_user, action: :view, resource: @patient)
  render json: @patient
end
```

```ruby
# BAD: Full record exposed
render json: @patient.as_json

# GOOD: Minimum necessary
render json: @patient.as_json(only: [:id, :name, :appointment_date])
```

## Severity

- **CRITICAL**: No audit trail for PHI access, PHI transmitted without encryption
- **HIGH**: Missing access controls on PHI endpoints, no session timeout
- **MEDIUM**: Incomplete audit logging, overly broad data responses
- **LOW**: Missing integrity checks, documentation gaps for BAAs

## False Positives to Avoid

- Audit logging handled by middleware/callbacks not visible in the controller
- Encryption handled at infrastructure level (database-level encryption, TLS termination at load balancer)
- Internal service-to-service calls within a trusted network boundary
- Non-PHI endpoints that happen to be in a healthcare application
