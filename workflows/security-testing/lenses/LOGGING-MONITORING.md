# Logging & Monitoring

Detect missing security event logging, sensitive data in logs, and insufficient monitoring for security-relevant events.

## What to Flag

### Missing Security Event Logging
- Failed login attempts not logged
- Permission denied / authorization failures not logged
- PHI access not audit-logged
- Account lockout events not logged
- Password changes, MFA enrollment/removal not logged
- Admin actions not logged
- Data export/bulk access not logged

### Sensitive Data in Logs
- Passwords, tokens, or API keys in log messages
- PHI fields logged (see PHI-EXPOSURE lens for comprehensive list)
- Full request bodies logged without filtering sensitive params
- Database query logs including sensitive parameter values
- Credit card numbers or financial data in logs

### Log Integrity
- Application-level code that can modify or delete audit logs
- Audit logs stored in same database as application data (deletable by app)
- No log rotation or retention policy evident
- Missing timestamps or user attribution in log entries

### Monitoring Gaps
- No alerting mechanism for repeated failed logins (brute force)
- No detection of unusual data access patterns (bulk PHI queries)
- Debug logging enabled in production configuration
- Mobile: debug/verbose logging in release build configuration

## Patterns

```ruby
# BAD: Password in log
Rails.logger.info("User login: #{email}, password: #{password}")

# GOOD: No sensitive data
Rails.logger.info("Login attempt for user_id=#{user.id} from_ip=#{request.remote_ip}")
```

```ruby
# BAD: Full params logged (may contain PHI/secrets)
Rails.logger.debug("Params: #{params.inspect}")

# GOOD: Filter sensitive params
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [:password, :ssn, :token, :secret]
```

```ruby
# BAD: Missing audit log on sensitive action
def destroy
  @patient.destroy
  head :no_content
end

# GOOD: Audit logged
def destroy
  AuditLog.record(user: current_user, action: :delete, resource: @patient)
  @patient.destroy
  head :no_content
end
```

## Severity

- **CRITICAL**: Passwords/tokens in logs, PHI in logs shipped to external services
- **HIGH**: No logging of failed auth attempts, no PHI access audit trail
- **MEDIUM**: Debug logging in production, missing admin action logging
- **LOW**: Missing log rotation, incomplete audit attribution

## False Positives to Avoid

- `filter_parameters` configured to redact sensitive fields (check initializers)
- Audit logging handled by model callbacks or middleware (not visible in controller)
- Log levels configured to suppress debug in production via environment config
- Third-party audit services (e.g., PaperTrail) providing change tracking
