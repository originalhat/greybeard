# WebSocket Broadcast Reviewer

Detect breaking changes to websocket broadcasts that will cause clients to silently stop receiving updates.

## Why This Matters

WebSocket changes are dangerous because:
- They fail silently (no HTTP errors)
- Users see "stale" UIs with no error messages
- Automated tests often mock broadcasts, missing regressions

## What to Flag

### Broadcast Removal (Critical)
- Removing `broadcast` calls from models/controllers
- Removing callbacks that trigger broadcasts
- Removing entire channel classes
- Conditional logic changes that skip broadcasts

### Channel/Topic Changes (Critical)
- Renaming channel or topic names
- Changing stream identifiers
- Modifying subscription parameters

### Payload Changes (High)
- Removing or renaming fields in broadcast data
- Changing data types or structure
- Removing event type/action fields

### Timing Changes (High)
- Changing when broadcasts fire (after_save → after_commit)
- Adding conditions that prevent broadcasts
- Moving broadcasts to background jobs without delivery guarantee

## Patterns

```ruby
# BAD: Broadcast removed during refactoring
# Before:
after_commit on: :update do
  broadcast(:channel, :event, id)
end

# After:
after_commit on: :update do
  # broadcast removed - clients stop receiving updates!
end
```

```ruby
# BAD: Condition added that may skip broadcasts
after_commit on: :update do
  return if minor_change?  # New condition might skip needed broadcasts
  broadcast(:channel, :event, id)
end
```

```ruby
# BAD: Channel name changed
# Before:
stream_from "patient_#{id}"
# After:
stream_from "patients:#{id}"  # Format change breaks clients
```

## Safe Changes (Non-Breaking)

- Adding new broadcasts
- Adding new fields to payloads
- Adding new channels
- Performance improvements that preserve behavior

## Severity

- **CRITICAL**: Clients stop receiving updates entirely
- **HIGH**: Payload structure changes break client parsing
- **MEDIUM**: Timing changes may cause race conditions

## False Positives to Avoid

- Adding new broadcasts (additive)
- Adding new fields to payloads
- Internal refactoring that preserves all broadcast calls
- Test file changes
