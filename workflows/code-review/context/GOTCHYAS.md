### Breaking API Changes

We need to be super mindful about any api/websocket/etc that could break any of our clients.

There's a criss-cross of dependencies between all of the apps in the repos/ directory

### Dropping Tables in Migrations

Production databases may have tables enrolled in PostgreSQL logical replication sets. A plain `drop_table` will fail with `PG::DependentObjectsStillExist` even though it succeeds locally. Use `drop_table :table_name, force: :cascade` to handle this. Better yet, split destructive migrations into two deploys: (1) add new structure + copy data, (2) drop old table in a follow-up. This also makes rollback safer since old code can still read the original table during the transition.

### ActiveStorage Route Helpers Are Undrawn in Production — Use `blob.url`, Not `rails_blob_path`

**Do not call `rails_blob_path` / `rails_blob_url` / `url_for(attachment)` anywhere in this app.** Production and default (amazon-backed) staging set `config.active_storage.draw_routes = false` (`config/environments/production.rb`, `staging.rb`) so that attachment access is authenticated rather than served over guessable public routes. When those routes aren't drawn, the ActiveStorage route helpers **don't exist as methods** — even in classes that *do* mix in the helpers. `Presenters::Base` already does `include Rails.application.routes.url_helpers`, so this is **not** a missing-include problem: the method is genuinely undefined at runtime in prod.

The trap: development (`draw_routes = true`) and the `LOCAL_IMAGE_STORAGE=true` staging branch (`:local` service, `draw_routes = true`) **do** draw the routes, so `rails_blob_path` works there and passes every local test and review click-through. It only blows up in prod/default-staging.

This shipped as a PROD incident (ER-1523, PR #836 introduced it): `Presenters::ScheduledStack#render_pending_files` used `rails_blob_path(attachment, only_path: true)` inside `pending_files.attachments.map { … }`, raising `NoMethodError: undefined method 'rails_blob_path'` on `GET /care_requests/:id` — but only for records that actually **have** pending attachments, so it hid for weeks behind the empty-collection happy path.

**The correct pattern (used by every other presenter — `simple_patient_file.rb`, `active_storage_attachment.rb`):**

```ruby
# BAD: depends on ActiveStorage routes that prod doesn't draw
url: rails_blob_path(attachment, only_path: true)

# GOOD: signed, expiring URL straight from the service (S3 in prod)
url: attachment.blob.url
```

When reviewing a presenter/serializer/PORO/job that generates attachment URLs:

1. Flag any `rails_blob_path` / `rails_blob_url` / `url_for(attachment)` — require `blob.url` instead.
2. `blob.url` returns an **expiring** signed URL (Rails' 5-min default; `urls_expire_in` is unset). Confirm the client renders it promptly and doesn't cache/persist it for a later click, or the link 403s.
3. Confirm a spec exercises a record that actually **has** the attachment (populated branch), and validate on **default amazon-backed staging**, not the `LOCAL_IMAGE_STORAGE=true` branch which draws routes and masks the bug.

See the `ROUTE-URL-HELPER-CONTEXT` and `TESTING-COVERAGE` lenses for the general form.

### Preload Task Associations via `Presenters::Task.preload` — Never Hand-Maintain the List

**Use the shared `Presenters::Task.preload` list wherever tasks are eager-loaded. Do not hand-roll a bespoke `.preload(...)` list.** `TasksController#index` uses the shared list; a drifted, hand-maintained copy in `#care_request_tasks_index` is what shipped ER-1532.

Two stacked traps, both live in this app:

1. **`patient_files: :file` is an invalid preload.** `PatientFile` uses `has_one_attached :file`, so the association is `file_attachment` (+ `file_blob`) — there is no association named `file`. `preload(patient_files: :file)` raises `ActiveRecord::AssociationNotFoundError`. The shared list preloads attachments correctly (`patient_files: { file_attachment: :blob }`); a copy-pasted list gets this wrong.
2. **An unassigned `.preload(...)` is a no-op that *masks* trap 1.** `#care_request_tasks_index` had `tasks = ...; tasks.preload(..., patient_files: :file)` — the return value was discarded, so the invalid clause never executed and never raised (it just quietly N+1'd). PR #860 "fixed the N+1" by reassigning (`tasks = tasks.preload(...)`), which made the invalid list run for the first time → 500 on every care request with an attached file. The reassignment *looked* like a trivial cleanup; it activated a dormant, invalid code path.

When reviewing task eager-loading:

1. Require `Presenters::Task.preload` (the single source of truth); flag any hand-maintained duplicate list.
2. Flag `patient_files: :file` (or any `has_one_attached`/`has_many_attached` name) as a preload target — it must be `{ *_attachment: :blob }` / `with_attached_*`.
3. Treat assigning-back a previously-discarded `.preload` as a behavior change on a code path that likely has no test — require a request spec exercising a task **with an attached file** (the exact repro PR #861 added).

See the `N-PLUS-ONE-QUERY`, `OPPORTUNISTIC-REFACTOR`, and `TESTING-COVERAGE` lenses for the general forms.

### Patient Submission Endpoints Must Re-Enter the Provider Queue

The provider queue is driven by `ActionItem.unresolved` joined through cards. A care request only appears in `/queue` while it has at least one unresolved `ActionItem`.

`Card.after_create` auto-creates an `ActionItem` only when the **patient authored the card** (e.g. sending a message). For flows where a patient *completes a provider-authored card* — submitting a question set, submitting a PHQ-9/GAD-7 screener, anything similar — the card already exists, the after_create callback does not fire, and the controller must explicitly create the action item:

```ruby
unless screener_request.card.action_item
  screener_request.card.create_action_item!(
    claimed_by: care_request.picked_up_by,
  )
end
```

When reviewing a new `PatientApi::*Controller` action (or any flow where a patient submits/completes/answers something against an existing card), confirm:

1. An `ActionItem` is created on the relevant card (or one already exists and is being reused — usually guarded by `unless card.action_item`).
2. The action item creation is inside the same `ActiveRecord::Base.transaction` as the submission write.
3. A spec asserts `ActionItem.count` changes by 1 on submission.

If the PR adds a new "patient submits X" flow and none of the above are present, the care request will silently disappear from the provider queue after submission (this exact bug shipped in PROD-1684).

The longer-term fix is to move action-item creation into model `after_commit` callbacks on the submission model itself (e.g. `Patients::MentalHealthScreening`, `QuestionSet`) so future submission types only need a model-level invariant rather than controller discipline.

### origami_claims: `Individual` Is the Person. `Member`, `Dependent`, `Broker`, `Admin` Are Roles.

In `origami_claims`, `Groups::Models::Individual` is the one row per human. `Member`, `Dependent`, `Broker`, and `Admin` are roles that hang off it (`Individual has_many :members / :dependents / :brokers / :admins`), and one person can hold several over time (a member at two companies) or none of them.

**Anything keyed to a person hangs off `Individual`, not off a role.** `SanaCare::Models::Patient` `belongs_to :individual` (required); `member` and `dependent` are optional and are only the role that existed when the patient was created. `Patient.for` accepts only an `Individual`. Phones and addresses resolve through `owner.individual`.

**Populations that have an `Individual` and a Sana Care `Patient` but no `Member` row:**
- **Brokers** — `Patient.create_through_api!` is called with `person: nil` and writes `external_id: 'BROKER'`; consent lives in `Individual#sc_broker_consent_at`.
- **SCaaSA standalone registrants** — `Individual#standalone?` (no member, dependent, admin, or broker) with `sc_standalone_consent_at`; reconciled via `IndividualReconciliation` state `scaasa_access`.

Shipped as review feedback on PR #9049 (PROD-2097): the Care Platform demographic sync subscribed to `MemberUpdatedEvent` / `DependentUpdatedEvent`, so brokers and SCaaSA registrants never synced. The `review --fix` pass then changed the worker to read `patient.member || patient.dependent || patient.individual`, which reads a possibly terminated or superseded role row and would overwrite current data on CP. The correct shape was an `IndividualUpdatedEvent` and a payload built from `patient.individual`.

When reviewing anything that syncs, notifies, or recalculates for a person:

1. The trigger is on `Individual` (an `Individual*Event` or an `Individual` callback), or the PR explains why a role-only trigger is correct for every population above.
2. The payload reads from `patient.individual` / `owner.individual`, never from `patient.member || ...` fallbacks. Any `member || dependent || individual` chain is a finding.
3. `Member`/`Dependent` edits reach `Individual` only through `Groups::Models::Concerns::Person#update_individual!`. If a field the sync needs is missing there (sex was, until #9049), add it to `update_individual!`. Do not read the role directly to get a "fresher" value — that re-splits the source of truth.
4. Specs cover at least one `Patient` with `member: nil, dependent: nil`.

See the `TRIGGER-COVERAGE` lens for the general form.
