### Breaking API Changes

We need to be super mindful about any api/websocket/etc that could break any of our clients.

There's a criss-cross of dependencies between all of the apps in the repos/ directory

### Dropping Tables in Migrations

Production databases may have tables enrolled in PostgreSQL logical replication sets. A plain `drop_table` will fail with `PG::DependentObjectsStillExist` even though it succeeds locally. Use `drop_table :table_name, force: :cascade` to handle this. Better yet, split destructive migrations into two deploys: (1) add new structure + copy data, (2) drop old table in a follow-up. This also makes rollback safer since old code can still read the original table during the transition.

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
