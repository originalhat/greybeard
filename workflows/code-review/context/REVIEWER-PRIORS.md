# Reviewer Priors

What the humans who review these repos reliably ask for, taken from their review comments on merged PRs. Grown by `review --calibrate`; each entry cites the PR it came from. A prior is a team convention, not a defect: raise it as a nit unless a lens gives it a consequence.

When a diff matches a prior, the finding names it (`REVIEWER-PRIORS: adapter owns budgets`) so the author sees the convention rather than an opinion.

## care_platform

### Rich models over resolver services
A lookup or resolution whose only subject is one model is a class method on that model, not a `Fabric::XResolver` service. (#980: `PatientResolver` became `FabricPatient.for_visit`.)

### One object per job, not a chain of service objects
When several service objects are constructed per item and share no state, they are one job. Combine them into one object that holds the shared view (a cached list, a memoised read) rather than adding a cache parameter to each. (#980: `ProvisionDependents` + `ProvisionDependent` + `DependentPatientLookup` became `Fabric::ProvisionFamily`.)

### The adapter owns its budgets and credentials
Timeouts, retry counts, and the member token live on the client, set at construction. Services do not define their own `CONNECT_TIMEOUT` / `RESPONSE_TIMEOUT` copies or pass `auth:` per call. (#980: six files carried the same two constants; twenty `auth:` kwargs on the client.)

### Cache repeated vendor lookups within a request
The same list or the same record read more than once in one request or launch is a finding, even when each read is cheap. (#980, David: family list re-fetched per child.)

### Rescue the vendor's 404 where a list can be stale
A per-item read off a list the vendor gave you can 404; skip that item, do not end the lookup. (#980, David.)

### Invariants are constraints, not conventions
"Exactly one of these two foreign keys is set" is a model validation and a database check, not a comment. (#980, Jeremy.)

### A migration never assumes a table is empty
If the PR before this one could deploy first and take traffic, backfill before the NOT NULL. Say what was seeded to prove it. (#980, Jeremy; #981.)

### A new nullable identity column needs a backfill story
Adding a column that a caller only sends on create leaves every existing row null forever. Name the backfill, even when it lives in the other repo. (#980, Jeremy: `individual_uuid`.)

### Pass fields, not the hash
When a method uses two ids from a payload, take the two ids. (#980, Jeremy.)

### Top-level `Fabric*` models, `Fabric::` services
Models are `FabricPatient`, `FabricVisit`, `FabricProvider`; services and adapters are under `Fabric::`. A `Fabric::Patient` would shadow `Patient` inside every Fabric service. (#980, #981.)
