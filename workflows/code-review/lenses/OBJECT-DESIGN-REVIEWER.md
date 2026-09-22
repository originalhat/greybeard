# Object Design Reviewer

Detect objects whose boundaries are in the wrong place: signatures that leak how the object works, knowledge that lives in more files than it needs to, and service objects that exist because nobody asked whether the model could do the job.

`SEPARATION-OF-CONCERNS` asks which *layer* logic belongs in. `CLARITY-SIMPLICITY` asks whether a method is readable. This lens asks whether this is the right *object*, and whether its public surface says only what a caller needs to know.

## What to Flag

### Signatures that leak implementation
- Credentials, tokens, timeouts, retry counts, or a collaborator (`client:`) passed on every call. The caller now knows how the object talks to its dependency. These belong in the constructor, set once, so the scoped calls take only what they are about.
- A whole payload or params hash passed where the method uses two fields from it. The method's real inputs are hidden; every caller must know the payload shape.
  **How to check:** for each new or changed method that takes a hash, payload, or params argument, count the keys it reads. Two or fewer is a nit: name the keys and suggest passing them.
- Optional keyword arguments that only tests use.

### Knowledge in more places than one
- The same constant (a timeout, a limit, a header name, a metric prefix) defined in more than one file. Count the files and name them. Two copies drift; six copies are a config the adapter should own.
  **How to check:** for every constant the diff defines or redefines, grep the app for its name (`grep -rn 'RESPONSE_TIMEOUT' app/`) and report the file count with the list. Three or more files is HIGH whether the diff added the first copy or the sixth. Do this before deciding there is no duplication; reading the diff alone cannot see the other copies.
- The same mapping (model → payload, payload → attributes) written in two services.
- A rule about one model (how to resolve it from an external id, what makes two rows the same person) implemented outside that model.

### Service objects that should not exist, or should be one
- A `self.call` / `self.fetch` class method whose only job is `new(...).call`, on a class with one public method and no reuse of the instance. The wrapper is ceremony.
- A chain of service objects, each constructed per item, that share no state, so every one repeats the lookup the last one did. The shape to look for: `Foo.call` loops and calls `Bar.call` per item, and `Bar` calls `Baz.fetch`, and `Baz` fetches a list. See `N-PLUS-ONE-QUERY` for the cost; here the finding is that the three objects are one job and one object should hold the shared view.
- A "resolver", "lookup", or "finder" service whose only subject is one ActiveRecord model and whose only dependency is that model's table. That is a class method on the model.
- A service that exists to hold two constants and a private method.

### Models that know nothing
- A model with associations and validations only, while the rules about it (who owns it, how it is found, when it is one thing or another) live in services. Expressiveness belongs on the object that has the data.

### Consistency with the neighbours
- A new object that follows a different construction pattern from its siblings in the same directory (one takes `client:` per call, the rest hold it) without saying why.
- A new class that breaks the naming convention its siblings use (namespaced where siblings are top-level, or the reverse).

## The Pattern Rule

**Adding another instance of an existing pattern puts the pattern in scope.** If the branch adds the sixth method that takes `auth:, connect_timeout:, response_timeout:` per call, the finding is not pre-existing: it names the new method and the five it copied, and the fix is the pattern, not the one method. Fact-check (step 8) applies pre-existing per line, so the new lines are this branch's.

## Patterns

```ruby
# BAD: every call carries the credential and the budget
client.patients(auth: token, connect_timeout: 1, response_timeout: 2)
client.patient(id, auth: token, connect_timeout: 1, response_timeout: 2)

# GOOD: scoped once, calls take only their subject
client = Client.new(auth: token)
client.patients
client.patient(id)
```

```ruby
# BAD: a resolver service that only touches one model
Fabric::PatientResolver.new.resolve(visit)   # Patient.find_by(...) || Patient.find_by(...)

# GOOD: the model answers questions about itself
FabricPatient.for_visit(fabric_id:, external_identifier:)
```

## Severity

- **HIGH**: the same operational constant in three or more files; a service chain that repeats a remote lookup per item
- **MEDIUM**: credentials or budgets per call; a resolver that belongs on the model; a payload hash where two fields would do
- **LOW / nit**: `self.call` ceremony; naming inconsistent with siblings

## False Positives to Avoid

- A constructor that takes a collaborator for dependency injection in tests, when production callers use the default
- A service that orchestrates two or more models or a model and an external system; that is what services are for
- Constants that are the same number by coincidence and mean different things (a UI page size and an API page size)
- Small apps or early code where one service is the whole feature
