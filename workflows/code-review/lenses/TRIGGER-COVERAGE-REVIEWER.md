# Trigger Coverage Reviewer

When a change hooks new behavior to a trigger — an event subscription, a model callback, a webhook, a cron filter, a scope — verify the trigger fires for **every population** that can reach the record the behavior acts on, and that the behavior reads its data from that record's identity, not from one of its snapshots. Then check the other direction: the handler must cope with **every population the trigger fires for**, not only the one the author pictured.

## Why This Matters

The author picks a trigger from the entity they were thinking about while writing the ticket. The record the behavior acts on is usually owned by a broader set of entities than that. Nothing fails: the behavior runs correctly for the population the author had in mind and never runs for the others. There is no error to find it by later, only a support ticket months on.

The evidence is almost always in the diff's own files. A required `belongs_to` on the target model is the identity. Optional `belongs_to`s are roles or snapshots. A trigger keyed to a snapshot misses everyone who has the identity without that snapshot. The inverse evidence is one model read away too: a polymorphic `belongs_to` with an `inclusion` allowlist, an STI base, or a type enum names every population the trigger fires for.

## Method

Work this in order. Do not judge the trigger until step 3 is complete.

1. **Name the target record** — the row the new behavior reads from or acts on (the thing being synced, notified, recalculated). If the PR doesn't say, follow the code from the trigger to the first persistent record it loads.
2. **Classify the target's associations.** Read the model, not the PR description. Required `belongs_to` = identity. Optional `belongs_to` = role or snapshot: grep for every write to its FK. Set once at creation and never re-pointed = snapshot. Maintained in step with the identity = role. A `has_many` back from the identity to several role models is the tell that one person can wear several hats or none.
3. **Enumerate the populations.** A population is any partition of the target's rows the trigger might treat differently: by **role** (who owns it), by **lifecycle stage** (registered or not, active or terminated), or by **field owner** (a synced field that lives on a different model than the one the trigger watches). Find every creation path for the target (`create!`, `create_through_api!`, factories, importers) and list who gets one. Look for literals that name a population the trigger doesn't (`'BROKER'`, `standalone`, `person: nil`, `member: nil`). Look for consent or flag columns on the identity that name a population (`*_consent_at`, `standalone?`). For each field the behavior syncs, find which model actually stores it.
4. **Check the trigger against each population.** For each population from step 3: does the chosen event/callback fire when *their* data changes? A population with the identity but without the role the trigger watches is a finding.
5. **Check the read source.** Where does the behavior get its values — the identity, or a role/snapshot? If from a snapshot, ask two things: is the FK ever re-pointed after creation (if not, a terminated or superseded row is still what gets read), and are all fields propagated into the identity? A missing propagation is fixed by propagating, not by reading around the identity. Also check the lookup that finds the target: a guard on an unrelated column (`user_id.present?`) excludes a lifecycle stage that still owns the target.

6. **Enumerate the trigger's own population.** A model callback, or an event published from one, fires for every row of that model. Read the model the trigger hangs off. A polymorphic `belongs_to` (list the `inclusion` validation or `PolymorphicClasses` entries), an STI base class, or a type/kind enum each names a population. For each: does the handler handle it, filter it explicitly, or raise? Safe navigation (`&.`) guards nil, not a different type.

Emit the population table so nothing is dropped:

| Population | Has target? | Trigger fires? | Read source current? | Handler copes? |
|------------|-------------|----------------|----------------------|----------------|
| Member (employee) | yes | yes | yes | yes |
| Adult dependent | yes | yes | yes | yes |
| Broker | yes (`external_id: 'BROKER'`) | **no** — no Member row | n/a | n/a |
| Standalone registrant | yes | **no** — no Member row | n/a | n/a |
| Any, email field | yes | **no** — email lives on User, trigger watches Member | n/a | n/a |
| Address owned by Provider, Company, ProviderLocation… (7 of 10 owner types) | no | **yes** — `after_save_commit` on every Address | n/a | **no** — `owner.individual` raises in the job |

## What to Flag

### Trigger on a Role, Target on the Identity
The behavior acts on a record that belongs to the identity, but the subscription/callback is on one role model. Everyone holding the identity through a different role, or through no role, is skipped.

### Read From a Snapshot
The behavior builds its payload from an optional association (`patient.member || patient.individual`) instead of the required one. A stale, terminated, or superseded role row is written over the current identity data. Last-write-wins makes this an overwrite, not a no-op.

### Found by the Identity, Read From a Stale Row
Same severity as a snapshot read: the target is found through the identity, then the payload reads a role row that is no longer current (a second Member row after a re-hire, or the Member row when the edit was on the Dependent). The wrong values land.

### Handler Assumes One Shape of a Shared Trigger
The trigger lives on a model with a polymorphic owner, an STI base, or a type enum, and the handler calls a method only some of those types define. It runs correctly for the author's type and raises for the rest. In a job, every raise retries and reports, so one deploy produces thousands of error occurrences from records that were never in scope.

### Field the Trigger Cannot See
A synced field is stored on a model the trigger does not watch (email on User, watched event on Member). The field appears in the payload map and never changes through this path. Coverage is claimed, not delivered.

### Propagation Gap Patched by Bypass
A field is missing from the role → identity propagation, and the change reads the role directly to get a fresh value. The right fix adds the field to the propagation. Reading around the identity leaves every other reader of the identity stale and re-splits the source of truth.

### PR Description as Evidence
The PR asserts a population is handled ("brokers no-op naturally") without a test or code path showing it. Verify against the model and the creation paths, not the description.

## Patterns

```ruby
# BAD: Patient belongs_to :individual (required); member/dependent optional.
# Brokers and standalone registrants have a Patient and no Member.
PubSub.subscribe(MemberUpdatedEvent, PatientSyncListener, :sync)
payload = build(patient.member || patient.dependent || patient.individual)

# GOOD: trigger and read on the identity; propagate what was missing.
PubSub.subscribe(IndividualUpdatedEvent, PatientSyncListener, :sync)
payload = build(patient.individual)
# and in Person#update_individual!: changed_attrs[:sex] = sex if saved_change_to_attribute?(:sex)

# BAD: AddressUpdatedEvent fires for all ten Address owner types; three define #individual.
enqueue(address&.owner&.individual)

# GOOD: name the population the handler is for, or ask the object.
owner = address&.owner
enqueue(owner.individual) if owner.respond_to?(:individual)
```

## Severity

- **HIGH**: a population that owns the target never triggers the behavior; a snapshot or stale-row read that can overwrite current data; a handler that raises for a population the trigger fires for
- **MEDIUM**: propagation gap patched by reading around the identity; a synced field with no trigger path; a lookup guard that excludes a lifecycle stage; population claimed handled in the PR with no code or test backing it
- **LOW**: population table incomplete but every found population is covered

## False Positives to Avoid

- The target genuinely belongs to the role model, not the identity — confirm by reading `belongs_to` presence, not by intuition
- The PR explicitly scopes the behavior to one population and says why, and the excluded populations cannot hold the target
- The snapshot is the correct source because the identity is not maintained for that field, and the PR says so — still confirm no other reader depends on the identity
- Single-population systems with one model and no role hierarchy
- Every allowed type responds to the method the handler calls — confirm by reading each type, not by the allowlist's length
