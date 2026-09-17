# Gap: a trigger on a shared polymorphic model reaches handlers written for one owner

**Status:** applied 2026-09-17 (lenses, GOTCHYAS, extraction pipeline). Data fixes in layer 3 wait for the next `catch up knowledge for origami_claims` run.
**Source incident:** origami_claims PR #9049 → Rollbar item 16233 (2,472 occurrences over three days) → PR #9069

## What happened

PR #9049 (merged 2026-09-14) added `PatientSyncListener#sync_address`:

```ruby
def sync_address
  address = Address.find_by(uuid: @event.address_uuid)
  enqueue(address&.owner&.individual)
end
```

`AddressUpdatedEvent` is published from `Address#after_save_commit :update_demographics` for **every** address row. `Address#owner` is polymorphic and the model allowlists ten owner types (`address.rb:38-53`): `Member`, `Dependent`, `Broker`, `Company`, `Provider`, `ProviderLocation`, `ProviderRequest`, `ProviderSelfNomination`, `ProviderSearch::Location`, `Ancillary::Beneficiary`. Only the first three define `individual`. The first provider or company address edit after deploy raised `NoMethodError: undefined method 'individual' for an instance of CareNetwork::Models::Provider` inside Sidekiq, so every occurrence also retried.

`Phone#owner` allowlists only `Member`, `Dependent`, `Broker`, so the sibling `sync_phone` is safe today, but by coincidence of the allowlist, not by design.

The spec for `sync_address` at #9049 had one example, a member-owned address.

PR #9069 patched it with an allowlist of `Member` and `Dependent` and dropped `Broker`, which the #9069 review caught.

## Why the review of #9049 missed it

The review ran inside the implementation thread as `review --fix`. It opened `address.rb` to check payload fields (`current_address`, nil handling) and never read the `owner_type` inclusion list. Nothing asked it to:

1. **`TRIGGER-COVERAGE` only looks one way.** It asks "does the trigger fire for every population that owns the target?" (under-coverage). It never asks "does the handler cope with every population the trigger fires for?" (over-reach). That lens was written from the *first* #9049 gap (brokers not synced), which is the exact mirror of this one. Both gaps are the same mistake, the author reasoning from one owner type, seen from opposite sides.
2. **`TESTING-COVERAGE`'s "conditionally-executed code" list** names empty collections, optional associations, and rare enum branches. It does not name a polymorphic association where fixtures only ever build one concrete type. `address&.owner&.individual` looks nil-safe, and the lens has no prompt to ask "safe against which types?".
3. **No domain knowledge says `Address` is shared.** The extraction run's shared-infrastructure crawl recorded `polymorphic_classes.rb` and the `AddressOwner` concern ("Polymorphic address handling") but no domain record lists `Address` or `Phone` as an entity, and none records who may own one. The repo's own `domains/CLAUDE.md` only says addresses are "shared data not yet domainified". Separately, the ubiquitous-language entry for **Individual** is wrong: it describes the `Concerns::Individual` mixin ("a polymorphic type that can be either a Member or a Dependent"), not the `Groups::Models::Individual` identity row that GOTCHYAS and the repo docs call the one row per human.

## Proposal

Three layers, in priority order. Layer 1 is the one that would have caught this.

### 1. Lens: add the inverse direction to `TRIGGER-COVERAGE`

Extend the existing lens rather than adding a `POLYMORPHIC-REACH` lens. The trigger is where a shared model's whole population reaches code written for one owner; a general "any polymorphic read" lens would fire on presenters and scopes that already filter by type. If a non-trigger case ships later, split it out then.

Changes to `workflows/code-review/lenses/TRIGGER-COVERAGE-REVIEWER.md`:

**Intro sentence**, append: "…and, in the other direction, that the handler copes with every population the trigger fires for."

**Method, new step 6:**

> 6. **Enumerate the trigger's own population.** A model callback or an event published from one fires for every row of that model, not the rows the author pictured. Read the model the trigger hangs off. A polymorphic `belongs_to` (list the `inclusion` validation or `PolymorphicClasses` entries), an STI base class, or a type/kind enum each names a population. For each, does the handler handle it, filter it explicitly, or crash? Safe navigation (`&.`) guards nil, not a different type. Add the column to the population table.

**Population table**, add a column `Handler copes?` with rows like:

| Population | Has target? | Trigger fires? | Handler copes? |
|------------|-------------|----------------|----------------|
| Address owned by Member/Dependent/Broker | yes | yes | yes, `owner.individual` |
| Address owned by Provider/Company/ProviderLocation (7 types) | no | **yes** | **no**, `NoMethodError` in the job |

**What to Flag, new section:**

> ### Handler Assumes One Shape of a Shared Trigger
> The trigger lives on a model with a polymorphic owner, an STI base, or a type enum, and the handler calls a method only some of those types define. It runs correctly for the author's type and raises for the rest. In a job, every raise retries and reports, so one deploy produces thousands of error occurrences from records that were never in scope.

**Patterns**, add:

```ruby
# BAD: AddressUpdatedEvent fires for all ten Address owner types; three define #individual.
enqueue(address&.owner&.individual)

# GOOD: name the population the handler is for, or ask the object.
owner = address&.owner
enqueue(owner.individual) if owner.respond_to?(:individual)
```

**Severity**, HIGH: "…a handler that raises for a population the trigger fires for." **False positives**, add: "Every allowed type responds to the method the handler calls; confirm by reading each type, not the allowlist's length."

The lens is 97 lines; this adds roughly 20. Trim the second and third "What to Flag" sections (they overlap) to stay near the 100-line guideline.

### 1b. Lens: one bullet in `TESTING-COVERAGE`

Under "Conditionally-Executed Code the Happy Path Never Runs", add:

> - a **polymorphic association, STI base, or type column** where every fixture builds the same concrete type (`owner: member` when `owner_type` allows ten); require one example per type the code treats differently, plus one for a type it should ignore

### 2. Context: new `GOTCHYAS` entry for origami_claims

> ### origami_claims: `Address` and `Phone` Are Shared Models. `owner` Is Not a Person.
>
> `Address#owner` and `Phone#owner` are polymorphic. `Address` allows ten owner types (`app/models/address.rb`): `Member`, `Dependent`, `Broker`, `Company`, `Provider`, `ProviderLocation`, `ProviderRequest`, `ProviderSelfNomination`, `ProviderSearch::Location`, `Ancillary::Beneficiary`. `Phone` allows `Member`, `Dependent`, `Broker`. Only `Member`, `Dependent`, and `Broker` respond to `individual`. `owner_type` strings are unqualified (`"Broker"`, not `"Groups::Models::Broker"`) because `PolymorphicClasses` overrides domain namespacing.
>
> `AddressUpdatedEvent` and `PhoneUpdatedEvent` publish from `after_save_commit` on every row, for every owner type. A listener that does `owner.individual` runs for provider and company addresses too.
>
> Shipped as PR #9049 → Rollbar 16233 (2,472 `NoMethodError` occurrences in three days, every one a Sidekiq retry) → PR #9069. The #9069 fix allowlisted `Member` and `Dependent` and left out `Broker`, so broker address changes stopped reaching Care Platform.
>
> When reviewing anything that subscribes to `AddressUpdatedEvent` / `PhoneUpdatedEvent` or reaches through `address.owner` / `phone.owner`:
>
> 1. The handler filters by owner type or by `respond_to?(:individual)`, and the filter includes `Broker`.
> 2. A spec exercises a non-person owner (`create(:address, owner: create(:company))`) and asserts the handler returns without raising and without enqueueing.
> 3. A spec exercises a `Broker`-owned record and asserts it does enqueue.
>
> See the `TRIGGER-COVERAGE` lens for the general form and the `Individual` entry above for why brokers count.

### 3. Knowledge extraction: record association shape, and fix the data

The pipeline extracts *decisions*, and "which kinds of things may own an address" is one, but nothing in the pipeline asks for it.

- **`pipeline/01-crawler.md`, Step 3 "Data models":** after "with their key fields", add "and their **shape**: polymorphic associations with the allowed type list, STI hierarchies, and enum/type columns with their values. A shared model owned by several domains gets a `shared: yes` mark." Mirror this in the Data Map output format (`### Entities` → columns for Entity, Key Fields, Shape, Shared by).
- **`pipeline/02-extractor.md`, Step 3:** add to the list of what counts as a rule: "an allowlist of polymorphic owner types, STI subclasses, or enum values is a business decision about who or what may participate; extract it as a rule (usually `HIGH`, evidence is the validation itself)."
- **`templates/domain-record.md`, "Data This Domain Owns":** add a **Shape** column (`polymorphic owner: Member | Dependent | Broker | Company | …`) so a reviewer or the `DOMAIN-KNOWLEDGE` lens can look it up.
- **`lenses/DOMAIN-KNOWLEDGE-REVIEWER.md`:** new check under "Business Rule Compliance": "**Shape assumptions**: when the diff reaches through an association the domain record marks polymorphic or STI, confirm the code handles or filters every documented type."
- **Data fixes (next `catch up knowledge for origami_claims`):** add `Address`, `Phone`, `Email` to the shared-infrastructure domain record's Data table with their owner allowlists; correct the ubiquitous-language **Individual** entry to describe the identity model and move the mixin description to a `Concerns::Individual` note.

## What this does not fix

The `Concerns::Individual` mixin name colliding with the `Individual` model is a repo problem, not a greybeard one. Worth a line in `origami_claims/domains/CLAUDE.md`, but out of scope here.
