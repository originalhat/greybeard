# Insecure Deserialization

Detect unsafe deserialization of untrusted data that could lead to remote code execution or object manipulation.

## What to Flag

### Ruby Deserialization
- `Marshal.load` / `Marshal.restore` with untrusted input
- `YAML.load` (not `YAML.safe_load`) with external data
- `ERB.new(user_input).result` — template injection
- Cookie deserialization without integrity verification
- `Oj.load` without safe mode

### JavaScript/TypeScript Deserialization
- `eval()` on user-supplied data
- `JSON.parse()` result used to instantiate classes or call methods dynamically
- `new Function(user_input)` — code execution via constructor
- `node-serialize`, `js-yaml.load` (unsafe by default in older versions)

### Mobile Deserialization
- Android: `Parcelable`/`Serializable` from untrusted Intent extras
- iOS: `NSKeyedUnarchiver.unarchiveObject` with untrusted data
- Deep link parameters deserialized without validation

### General Patterns
- Accepting serialized objects from client-side (cookies, hidden fields, API params)
- Custom deserialization without type/class allowlisting
- Object instantiation based on user-supplied class names

## Patterns

```ruby
# BAD: Unsafe YAML load
config = YAML.load(params[:config_data])
data = YAML.load(File.read(user_uploaded_file))

# GOOD: Safe load with permitted classes
config = YAML.safe_load(params[:config_data], permitted_classes: [Symbol, Date])
```

```ruby
# BAD: Marshal with untrusted data
obj = Marshal.load(Base64.decode64(cookies[:session_data]))

# GOOD: Use JSON or signed/encrypted cookies
data = JSON.parse(cookies.signed[:session_data])
```

```javascript
// BAD: Dynamic method invocation from user input
const action = JSON.parse(req.body.action)
obj[action.method](action.args)

// GOOD: Allowlist of permitted actions
const ALLOWED = { 'save': obj.save, 'validate': obj.validate }
const fn = ALLOWED[req.body.action]
if (fn) fn.call(obj)
```

## Severity

- **CRITICAL**: `Marshal.load` or `YAML.load` with user-controlled input (RCE possible)
- **HIGH**: `eval()` or `new Function()` with external data, template injection
- **MEDIUM**: Deserialization from cookies or hidden fields without signing
- **LOW**: JSON deserialization used for dynamic dispatch (limited impact)

## False Positives to Avoid

- `YAML.safe_load` (safe by design)
- `Marshal.load` on trusted internal data (cache stores, internal queues with signing)
- `JSON.parse` used for plain data access (not object instantiation)
- Signed/encrypted Rails cookies (integrity-verified by framework)
