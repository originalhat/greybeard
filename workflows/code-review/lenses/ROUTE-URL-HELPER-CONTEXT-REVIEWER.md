# Route/URL Helper Context Reviewer

Detect Rails route and URL helpers that aren't actually available where they're called — a runtime `NoMethodError` that no compiler catches, that passes in dev/test, and that most tests skip because it hides behind an empty collection.

A route/URL helper resolves at runtime only if **both** are true:

1. **The helper module is mixed in** to the calling object, and
2. **The route it names is actually drawn** in the running environment.

Either one missing → `NoMethodError: undefined method '..._path'`. Dev and test usually satisfy both, so the crash surfaces only in production.

## Failure Mode 1 (most common here): ActiveStorage routes undrawn in prod

ActiveStorage helpers — `rails_blob_path`, `rails_blob_url`, `url_for(attachment)`, `rails_representation_url` — only exist when `config.active_storage.draw_routes = true`. Apps that authenticate attachment access set `draw_routes = false` in **production** (and any cloud-service staging), so these helpers are **undefined at runtime in prod even though the class correctly includes `url_helpers`**. This is *not* a missing-include problem.

The trap: `development` (and any local/disk-service config) draws the routes, so the call works in dev, passes every local spec and review click-through, and blows up only in prod.

```ruby
# BAD: undefined in prod when active_storage.draw_routes = false
url: rails_blob_path(attachment, only_path: true)

# GOOD: signed, expiring URL straight from the storage service (e.g. S3)
url: attachment.blob.url
```

**Prefer `blob.url` (or `variant.url`) for attachment URLs.** Match the pattern the rest of the app already uses. Note `blob.url` returns an **expiring** signed URL (Rails' default is 5 minutes unless `config.active_storage.urls_expire_in` is set) — confirm the client consumes it promptly and doesn't cache/persist it for a later click, or the link will 403.

## Failure Mode 2: helper module not mixed in

A plain **presenter / PORO / serializer / service object / model / background job** does not get route helpers by default. They exist for free only in **controllers, views, mailers, helpers**, or a class that does `include Rails.application.routes.url_helpers` (directly or via a base class such as `Presenters::Base` / `ApplicationSerializer`).

Verify the mixin on the class *or an ancestor* before trusting a `*_path`/`*_url` call in these contexts. Prefer generating the URL in the controller/view layer and passing the string in, rather than pulling routing into the domain layer.

## Failure Mode 3: `*_url` without a host

Absolute `*_url` helpers (and `blob.url` on the **disk** service) need a host. Without `default_url_options[:host]` / `ActiveStorage::Current.url_options` they raise `ArgumentError: Missing host to link to!` even where the module is included and routes are drawn. Cloud-service `blob.url` (S3, etc.) generates a direct signed URL and does not need a host.

## What to Flag

- `rails_blob_path` / `rails_blob_url` / `url_for(attachment)` / `rails_representation_url` anywhere — recommend `blob.url`; confirm the target environment draws the routes (Failure Mode 1).
- Any `*_path` / `*_url` inside a presenter, serializer, `as_json`, model method, or job whose class doesn't demonstrably include the helper module (Failure Mode 2).
- `*_url` / disk-service `blob.url` on a path where the host isn't configured (Failure Mode 3).

## Severity

- **CRITICAL**: On a code path real production data reaches (e.g. any record with an attachment) — guaranteed 500 in prod despite green local tests.
- **HIGH**: Behind an optional association / non-empty collection / rare state — fires only on specific data (see TESTING-COVERAGE for why these survive review).
- **MEDIUM**: `*_url` / disk `blob.url` used without a confirmed host.

## False Positives to Avoid

- Controllers, views, mailers, helpers — they have the helpers by framework default (subject to routes being drawn).
- Classes that include `Rails.application.routes.url_helpers` themselves or via a confirmed base class — *and* the named route is drawn in the target env.
- `blob.url` / `variant.url` — the correct, route-independent way to build attachment URLs.
- String/path literals that merely *look* like helpers but aren't method calls.
