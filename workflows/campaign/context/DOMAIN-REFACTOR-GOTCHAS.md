# Domain Refactor Gotchas

Applies to campaigns that move Ruby/Rails classes from one namespace to another (e.g., top-level `Foo` → `MyDomain::Models::Foo`). The class moves; its identity in some persistence and metaprogramming layers stays as the old string.

## Polymorphic associations: write side vs. read side

If the moved class is the **target** of any `belongs_to … polymorphic: true` association anywhere in the codebase, there's a `*_type` column somewhere storing the class name as a string.

- **Write side (`Class.polymorphic_name`)**: Rails calls this to generate the string when saving a polymorphic row. By default it returns `base_class.name`. After a namespace rename, this changes from the old short name to the new fully-qualified name — breaking validation allowlists that store the old string.
- **Read side (`ActiveRecord::Base.polymorphic_class_for(name)`)**: Rails calls this to resolve a stored string back to a class. By default it does `name.constantize`, which fails after the rename because the old top-level constant no longer exists.

**Fixes** typically come in some combination of:
- A central app-wide map (often `lib/polymorphic_classes.rb` or similar) that overrides both methods on `ApplicationRecord` to preserve old names. After a move, add a new entry mapping the old string to the new class.
- For the write side, an explicit per-class override: `def self.polymorphic_name; "OldName"; end`. Useful when the central map doesn't apply (see STI below).
- A data migration to update stored class names. Almost always more disruptive than the above; usually deferred.

**Don't change the bare strings in `ALLOWED_OWNER_TYPES` / `OWNER_TYPES` `%w[]` allowlists.** Those are the DB-stored values, not constant references. They should keep matching what's in the column.

## paper_trail has its own polymorphic map

`paper_trail`'s `PaperTrail::Version#item` uses its own `polymorphic_class_for` and does NOT delegate to `ApplicationRecord`'s. If the moved class includes `has_paper_trail`, the central app-wide map alone is insufficient — `Version#item` / `Version#reify` on existing rows will `NameError`.

Look in `config/initializers/paper_trail.rb` for an override on `PaperTrail::Version.polymorphic_class_for`. If one exists, add an entry for the moved class. If one doesn't, consider whether to add a delegation to the central map.

**Check whether the moved class actually uses paper_trail before assuming this is needed** — many models don't.

## STI subclasses inherit a broken `polymorphic_name` after a base class rename

For Single Table Inheritance subclasses, `Subclass.polymorphic_name` falls through to AR's default of `base_class.name`. Before the rename, that returned the old short string and matched consumer allowlists. After the rename, it returns the new fully-qualified string — and the central polymorphic map's `fetch(self)` lookup misses because the subclass isn't in the map (only the base is).

**Symptom**: a worker/service that uploads files (or otherwise creates a polymorphic owner row) for the STI subclass crashes with `ActiveRecord::RecordNotSaved` and validation failures on the owner_type allowlist.

**Fix**: override `polymorphic_name` on the **base** class directly to return the old string. The subclass inherits it via standard Ruby method lookup. Avoid changing the central `polymorphic_name` override to use `base_class` instead of `self` unless you can verify there are no STI subclasses currently relying on the existing semantics.

## `has_many` polymorphic-target associations need explicit `class_name:`

`has_many :foos, as: :patient` on a model in another package relies on Rails resolving `Foo` as a top-level constant. After the rename, that constant is gone. Rails' AR `compute_type` walking from the host model's namespace usually does NOT find a class in an unrelated namespace.

**Symptom**: `member.foos` or `dependent.foos` raises at runtime — not at boot, because the resolution is lazy.

**Fix**: add `class_name: 'NewNamespace::Foo'` to every such `has_many` declaration on related models. Easy to miss because:
1. The symbol-based association syntax looks like it doesn't reference the renamed class
2. Boot succeeds; failure only shows up when the association is exercised

When auditing, search for `has_many :{snake_case_name}` and `has_one :{snake_case_name}` across the codebase, not just constant references.

### The reverse direction is the easy miss: owner stays, target moves

The trap is worst — and most often missed — when the association *owner* stays put and the *target* is the class being moved. Example: you move `Foo` → `NewNamespace::Foo`, but `Bar` (which stays a top-level model) has `has_many :foos`. Since `Bar` is top-level, AR `compute_type` resolves `:foos` to the now-gone top-level `Foo` and raises `uninitialized constant Bar::Foo` / `Missing model class Foo for the Bar#foos association`.

**Why constant-grep misses it entirely**: the reference is the *symbol* `:foos`, never the constant `Foo`. A grep for `\bFoo\b` returns nothing on `Bar`. Only the symbol-association grep (`has_many :foos` / `has_one :foo` / `belongs_to :foo`) finds it — run it for every moved model, on both sides of every association, including models that are NOT in scope for relocation.

**Why review can't catch it but a test run can**: resolution is lazy — it fires only when the association is exercised (commonly a `dependent: :destroy` cascade on delete). Boot, packwerk, and static lens review all pass; the failure surfaces only when code actually destroys/traverses the owner. **Always run the owner model's destroy/CRUD specs (and any dashboard/serializer path that traverses it) after a move** — a green packwerk + green review is not sufficient evidence for an association-safe move.

## FactoryBot factories need explicit `class:` after a rename

```ruby
factory :foo do
  # ...
end
```

FactoryBot infers the class from the factory name via `String#camelize.constantize` — top-level lookup only, no namespace walking. After the rename, the factory crashes with `NameError`.

**Symptom**: many rspec failures (every test that uses the factory). The cascade can look much scarier than the underlying single-line fix.

**Fix**: add explicit class to each affected factory:
```ruby
factory :foo, class: 'NewNamespace::Foo' do
```

**When many tests fail, check factories first.** It's the single highest-leverage place to look.

## Packwerk: cross-package references need `package_todo.yml` entries

If the moved class is in a packwerk package different from a referencing model's package, **new** cross-package references will fail `packwerk check`. The acceptable workaround is to add the entries to the referencing package's `package_todo.yml` (each package has its own — they're alphabetical by referenced constant).

Common spots that trip the check:
- `has_many class_name: 'OtherDomain::Foo'` you added to fix the previous gotcha
- Updates to other domains' files that previously used the bare constant
- Workers/controllers in the root package that *are* checked by packwerk (verify in `packwerk.yml` whether `app/` and `lib/` are excluded)

`bin/packwerk update-todo` regenerates the file automatically if you can run it; otherwise add entries manually following the existing format.

## Bulk find-and-replace: word-boundary safe regex

Naive `s/Foo/NewNamespace::Foo/g` will mangle:
- `FooBar` → `NewNamespace::FooBar` (wrong)
- `'Foo'` string literals (sometimes wrong — see polymorphic allowlists above)
- `# Foo Events` comments (depends; usually keep)
- `Rails.logger.warn("Foo files exist...")` log messages (keep)

Use Perl with a negative-lookbehind/lookahead that excludes identifier characters AND `:` so already-namespaced refs don't double-prefix:

```bash
perl -i -pe 's/(?<![A-Za-z0-9_:])Foo(?![A-Za-z0-9_])/NewNamespace::Foo/g' file1.rb file2.rb
```

After running, **always** grep for the bare name to find what was left behind (intentionally or otherwise) and audit each. Common categories that need surgical handling rather than bulk:

- Polymorphic-type string allowlists (`%w[]` blocks)
- Log messages and error messages
- URL/param keys (e.g., `'Foo' => 'NewNamespace::Foo'` mappings)
- Old archive migrations under `db/migrate/archive/` — leave alone
- Schema annotation comments at the top of model files — Annotate regenerates them

## Sidekiq job class-name persistence (usually a non-issue)

If a worker enqueues jobs that pass the moved class name as a string argument, in-flight jobs from before the deploy can fail to deserialize. In practice this is rare:

- Workers usually pass record IDs, not class names. Check each worker's `perform_async`/`perform_at` calls.
- If the worker class itself was renamed, that's a different story — but worker class renames are usually out of scope for this kind of campaign.

Spot-check the worker code; document any risk in the PR; the mitigation (if needed) is usually a brief deploy-time alias retained for one release cycle.

## Test the migration via the PR-review lenses

These reviews catch the above gotchas best (assuming the Greybeard code-review lenses are run on the branch):

- **DATA-MIGRATION**: catches paper_trail map omissions, polymorphic stored-class-name divergence
- **CLARITY-SIMPLICITY**: surfaces empty placeholder classes that should be deleted
- **EXTENSIBILITY**: flags fully-qualified self-references inside the class itself
- **JOB-CONFIGURATION**: confirms worker class-string args are safe across the deploy
- **GOTCHYAS (repo-specific context)**: catches `has_many` polymorphic associations on related models that need explicit `class_name:`

Run the lenses before requesting human review — multiple of the issues above are non-obvious from a quick diff scan.

## Spec files travel with their subjects

When a class moves into `domains/{name}/`, its spec file should move alongside it. Most domain-organized Rails codebases adopt a mirror layout — either `domains/{name}/spec/{layer}/...` or `spec/domains/{name}/{layer}/...` — and the dominant convention is usually visible from any already-migrated example in the same domain.

**Don't take a strategy claim of "specs stay in `spec/`" at face value.** Verify by finding the spec for an already-migrated sibling class:

```bash
find . -name "{already_migrated_class}_spec.rb" -not -path "./node_modules/*"
```

If that spec lives under the domain (e.g., `domains/claims/spec/...`), the new specs go there too. The strategy must include `git mv` for the spec alongside the implementation.

**Symptom of skipping this:** a reviewer flags the inconsistency during PR review and you take a small follow-up commit on the same branch — fine if caught before merge, awkward to clean up later. If batches have already merged with the wrong layout, those orphan specs are an easy "fold into the next batch's PR" gesture rather than a stand-alone follow-up PR.

**Recipe step to add:** alongside the `git mv app/{layer}/{file}.rb domains/{domain}/{layer}/{file}.rb` step, include `git mv spec/{layer}/{file}_spec.rb domains/{domain}/spec/{layer}/{file}_spec.rb` (or whichever path the repo's convention dictates). No spec-body edits are needed — just the path.

## Workflow advice

- **Plan the polymorphic story first.** Before writing the recipe, enumerate every consumer of the moved class as a polymorphic target. Each consumer is a potential fix site that the recipe must cover.
- **Order matters within a batch.** Move the base class before its STI subclasses. Move parents before children in any other dependency graph.
- **One commit per item** keeps the diff reviewable and lets verifiers check each move independently. The "update all reference sites of constant X" work goes in the same commit as the move of X.
- **`git mv` preserves rename history.** Use it for files with substantial content. For empty/trivial files (< 5 lines), git often won't detect the rename even with `git mv` — that's fine.
- **Tests not running locally is common** in larger Ruby codebases due to bundler git-source gems, native extension build state, or Docker-only setups. Rely on CI; predict failures by tracing constant resolution paths manually.
- **Expect at least one CI iteration.** The factory + packwerk_todo + STI-polymorphic issues are nearly universal and easy to miss in the initial pass.
