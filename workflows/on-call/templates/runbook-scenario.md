# {Scenario Title}

> Repo: {repo} · Domain: {domain} · Last verified: {YYYY-MM-DD} @ {short SHA}
> History: {ER-XXXX}, {ER-YYYY}

**Symptom:**
What the engineer or reporter observes — the exact error text, the greyed-out button, the stuck state. Written so an agent can pattern-match a new ticket against it.

**Root cause:**
Why it happens, at the code level. Name the models, services, and the specific condition (`enrollment_managed_in_app?`, a nil policy, a stale derived status). This is what lets an agent adapt the fix to a variant.

**Fix:**
Step-by-step, least-invasive first (UI → upstream record → console). For console steps, use the `var = nil # fill in: …` convention, include a read-only preview before consequential writes, and add an idempotent guard where a re-run could double-apply.

```ruby
# example
record_id = nil  # fill in: e.g. 1234
record = SomeModel.find(record_id)
# ...
```

**Verification:**
How to confirm the fix worked — what to reload, what value to expect, which downstream artifact should now appear.

**Safety check:**
How the fix respects the relevant domain invariants (money flows correctly / history not rewritten / all payment waves / coverage consistency / correct COBRA beneficiary). Make this explicit whenever money or coverage is involved.

**Notes:**
Edge cases, gotchas that bit us before, feature-flag interactions, timing (batch windows / worker cadence — verified against code, not assumed), and related scenarios (`../{domain}/{other-scenario}.md`). Note any known systemic fix in flight (PR / Linear issue) that will make this runbook obsolete.
