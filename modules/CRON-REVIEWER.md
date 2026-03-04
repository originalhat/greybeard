# Cron Reviewer

Detect cron scheduling issues including syntax errors, timezone problems, and overlapping jobs.

## Cron Syntax Reference

```
  Minute   Hour   Day   Month   DayOfWeek
   0-59    0-23   1-31   1-12    0-7 (0,7=Sunday)

Examples:
'0 9 * * 1-5'     # 9:00 AM Mon-Fri
'0 0 * * *'       # Midnight daily
'*/30 * * * *'    # Every 30 minutes
'0 2 * * 0'       # 2 AM every Sunday
'0 0 1 * *'       # Midnight on 1st of month
```

## What to Flag

### Syntax Issues
- Wrong field order or values
- Invalid ranges or wildcards
- Ambiguous expressions

### Timezone Problems
- Cron without explicit timezone (uses server timezone)
- Jobs affected by Daylight Saving Time transitions
- Time comparisons mixing timezones

### Overlap Issues
- Job runs more frequently than it takes to complete
- Long-running jobs without locking
- Multiple instances competing for resources

### Timing Bugs
- Using `Time.now` instead of timezone-aware methods
- Assuming job runs at exact scheduled time (may be delayed)
- No handling for missed job runs (system downtime)

## Patterns

```ruby
# BAD: No timezone, job runs in server time
sidekiq_options cron: '0 9 * * *'

# GOOD: Explicit timezone
sidekiq_options cron: '0 9 * * *', tz: 'America/New_York'
```

```ruby
# BAD: Job takes 45min but runs every 30min
sidekiq_options cron: '*/30 * * * *'
def perform
  generate_report  # takes 45 minutes!
end

# GOOD: Add locking to prevent overlap
sidekiq_options cron: '*/30 * * * *', lock: :until_executed
```

## Severity

- **CRITICAL**: Job never runs, wrong timezone causes data issues
- **HIGH**: Jobs overlap and corrupt data, DST bugs
- **MEDIUM**: Inefficient scheduling, minor timing issues

## False Positives to Avoid

- Cron expressions that are correct but unfamiliar
- Jobs with appropriate locking already in place
- Short jobs that can't possibly overlap
