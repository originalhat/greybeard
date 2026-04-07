# Cross-Site Scripting (XSS)

Detect stored, reflected, and DOM-based XSS where untrusted input is rendered in HTML without proper sanitization.

## What to Flag

### Stored XSS
- User input saved to database and rendered without escaping
- Rich text fields rendered as raw HTML
- User-generated content displayed to other users without sanitization

### Reflected XSS
- Query parameters, URL fragments, or form inputs rendered directly in responses
- Error messages that echo back user input
- Search results displaying the search term unsanitized

### DOM-Based XSS
- `dangerouslySetInnerHTML` in React without sanitization
- `innerHTML`, `outerHTML`, `document.write()` with dynamic content
- `eval()`, `setTimeout(string)`, `new Function(string)` with user data
- URL hash/fragment values injected into DOM

### Rails-Specific
- `raw()` helper with user-controlled content
- `.html_safe` on user input
- Unescaped ERB: `<%== user_content %>`
- `render inline:` with interpolated user data

## Patterns

```ruby
# BAD: raw() with user content
<%= raw @comment.body %>
<%= @user.bio.html_safe %>

# GOOD: Default escaping or sanitize helper
<%= @comment.body %>
<%= sanitize @comment.body, tags: %w[b i em strong] %>
```

```jsx
// BAD: dangerouslySetInnerHTML without sanitizer
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// GOOD: Sanitize first
import DOMPurify from 'dompurify'
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

```javascript
// BAD: innerHTML with user data
element.innerHTML = `<span>${searchQuery}</span>`

// GOOD: textContent for plain text
element.textContent = searchQuery
```

## Severity

- **CRITICAL**: Stored XSS affecting other users (especially if PHI is accessible)
- **HIGH**: Reflected XSS in authenticated pages
- **MEDIUM**: DOM-based XSS requiring specific user interaction
- **LOW**: XSS in admin-only views with trusted users

## False Positives to Avoid

- React JSX expressions (`{variable}`) — auto-escaped by default
- ERB default output (`<%= %>`) — auto-escaped by Rails
- Static HTML content with no user input
- Markdown renderers with built-in sanitization
