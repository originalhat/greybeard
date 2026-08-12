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
- No alerting on exhausted retries
- Not distinguishing transient vs permanent failures

### Failure Signaling
A failure has to reach whatever decides what happens next. Flag any `rescue` that turns a failure into a normal-looking return value. Ask of each one: *if this fires in production, who finds out, and what does the next step do?*

- `rescue => e; log(e); nil` in a service the worker calls — the worker sees a successful return and carries on.
- Proceeding to a **destructive or finalizing** next step after a failed one: a cleanup/prune worker, marking the record complete, sending a success notice, deleting the source file. This is how a partial import becomes data loss.
- Rescuing **outside** the transaction boundary — earlier batches are committed, so "failed" and "partially succeeded" return the same thing. The result must carry how far it got.
- Errors written only to logs or a cache key nobody reads: no tracker report, no state change on the record the UI renders.
- A bare `rescue` around an entire `call` catches the bugs you wanted in the tracker along with the failures you expected.

## Patterns

```ruby
# BAD: No limits, retries forever
class FetchDataJob
  include Sidekiq::Job
  def perform(user_id) = fetch_from_api(user_id)
end

# GOOD: Configured limits + exponential backoff
class FetchDataJob
  include Sidekiq::Job
  sidekiq_options retry: 5, dead: true, timeout: 30.seconds
  sidekiq_retry_in { |count| (count ** 2) * 60 }
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
  log_and_alert(e)  # permanent failure, don't retry
rescue NetworkError
  raise             # transient, retry

# BAD: service rescues to nil, so the worker finalizes a failed import
def call
  import(rows)
rescue => e
  Rails.logger.error(e.message)   # caller sees a normal return
  nil
end
# caller then runs CleanupWorker (deletes "orphaned" rows) and marks complete

# GOOD: failure is part of the return contract (or just re-raise)
result = ImportService.call(upload)
return upload.update!(status: :failed, error: result.message) if result.failure?

CleanupWorker.perform_async(upload.id)
upload.update!(status: :complete)
```

## Severity

- **CRITICAL**: Jobs stuck forever, sensitive data exposed, a swallowed failure followed by a destructive finalizing step
- **HIGH**: Cascading failures, no alerting on failures, caller cannot distinguish success from failure
- **MEDIUM**: Suboptimal retry logic, inefficient queuing

## False Positives to Avoid

- Jobs with appropriate inherited configuration
- Short-lived jobs that don't need explicit timeouts
- Retry logic that correctly handles the job's error modes
