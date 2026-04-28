### Breaking API Changes

We need to be super mindful about any api/websocket/etc that could break any of our clients.

There's a criss-cross of dependencies between all of the apps in the repos/ directory

### Dropping Tables in Migrations

Production databases may have tables enrolled in PostgreSQL logical replication sets. A plain `drop_table` will fail with `PG::DependentObjectsStillExist` even though it succeeds locally. Use `drop_table :table_name, force: :cascade` to handle this. Better yet, split destructive migrations into two deploys: (1) add new structure + copy data, (2) drop old table in a follow-up. This also makes rollback safer since old code can still read the original table during the transition.
