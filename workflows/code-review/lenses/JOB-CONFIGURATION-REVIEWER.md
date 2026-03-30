# Job Configuration Reviewer

Detect misconfigured background jobs including missing timeouts, poor retry logic, and improper error handling.

## What to Flag

### Missing Configuration
- Jobs without timeout limits (can run forever)
- No retry limits (infinite retries hammer failing services)
- Missing dead letter queue handling
- No queue priority for different job types

### Retry Logic Issues
- Retrying on permanent errors (invalid data, missing records)
- No exponential backoff (hammers services)
- Missing circuit breakers for external APIs
- Aggressive retry causing cascading failures

### Job Arguments
- Large data payloads in job arguments (pass IDs, fetch data in job)
- Sensitive data in arguments (visible in logs/UI)
- Arguments that become stale (data changed since enqueue)

### Error Handling
- Swallowing errors silently
- No alerting on exhausted retries
- Not distinguishing transient vs permanent failures

## Patterns

```ruby
# BAD: No limits, retries forever
class FetchDataJob
  include Sidekiq::Job
  def perform(user_id)
    fetch_from_api(user_id)
  end
end

# GOOD: Configured limits
class FetchDataJob
  include Sidekiq::Job
  sidekiq_options retry: 5, dead: true, timeout: 30.seconds

  sidekiq_retry_in { |count| (count ** 2) * 60 }  # exponential backoff
end
```

```ruby
# BAD: Sensitive data in arguments
SendResetEmailJob.perform_async(user_id, token, email)

# GOOD: Fetch sensitive data in job
SendResetEmailJob.perform_async(password_reset_id)
```

```ruby
# BAD: Retries everything
rescue StandardError => e
  raise  # retries even permanent failures

# GOOD: Distinguish error types
rescue InvalidDataError
  # permanent failure, don't retry
  log_and_alert(e)
rescue NetworkError
  raise  # transient, retry
```

## Severity

- **CRITICAL**: Jobs stuck forever, sensitive data exposed
- **HIGH**: Cascading failures, no alerting on failures
- **MEDIUM**: Suboptimal retry logic, inefficient queuing

## False Positives to Avoid

- Jobs with appropriate inherited configuration
- Short-lived jobs that don't need explicit timeouts
- Retry logic that correctly handles the job's error modes
