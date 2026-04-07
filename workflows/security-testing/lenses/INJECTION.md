# Injection

Detect SQL injection, command injection, and other injection vulnerabilities where untrusted input is incorporated into interpreted commands.

## What to Flag

### SQL Injection
- String interpolation in SQL queries (`"WHERE id = #{params[:id]}"`)
- `find_by_sql`, `connection.execute`, `ActiveRecord::Base.connection.select_all` with user input
- Raw SQL in `.where()`, `.order()`, `.group()`, `.having()`, `.pluck()` with interpolation
- ORM bypass patterns that construct raw queries

### Command Injection
- `system()`, backticks, `exec()`, `%x{}`, `Open3.capture3` with user-controlled input
- `child_process.exec()`, `child_process.spawn()` with shell: true in Node
- Template strings in shell commands

### Other Injection
- LDAP queries with unsanitized input
- XPath injection
- Header injection (CRLF in HTTP headers)
- Email header injection

## Patterns

```ruby
# BAD: SQL injection via interpolation
User.where("email = '#{params[:email]}'")
User.order("#{params[:sort_column]} #{params[:sort_direction]}")

# GOOD: Parameterized queries
User.where(email: params[:email])
User.where("email = ?", params[:email])
User.order(Arel.sql(sanitize_sql_for_order(params[:sort])))
```

```ruby
# BAD: Command injection
system("convert #{params[:filename]} output.png")
`ls #{user_input}`

# GOOD: Array form avoids shell interpretation
system("convert", params[:filename], "output.png")
Open3.capture3("convert", filename, "output.png")
```

```javascript
// BAD: Command injection
exec(`ffmpeg -i ${req.body.url} output.mp4`)

// GOOD: Use array args, no shell
execFile('ffmpeg', ['-i', req.body.url, 'output.mp4'])
```

## Severity

- **CRITICAL**: SQL injection with user input reaching the query
- **HIGH**: Command injection, SQL injection in less accessible paths
- **MEDIUM**: Injection possible but input is partially validated
- **LOW**: Theoretical injection with no clear user input path

## False Positives to Avoid

- Parameterized queries and prepared statements (safe by design)
- Hardcoded strings in SQL (no user input)
- Array-form system calls (no shell interpretation)
- Admin-only code paths with trusted input
- ORM methods that auto-parameterize (`.where(key: value)`)
