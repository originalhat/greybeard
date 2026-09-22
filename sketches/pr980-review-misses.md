# Case study: what the code-review pipeline missed on care_platform #980

PR: https://github.com/origami-medical/care_platform/pull/980 (PROD-2137, merged 2026-09-22).

**Status (2026-09-22):** all ten ideas below were applied the same day. The ledger entry is at `$GREYBEARD_DATA/output/code-review/care_platform/calibration.md`.

Two human reviewers left 15 review threads. This compares each against what the pipeline
raised, using the run records in `$GREYBEARD_DATA/output/code-review/care_platform/` and the
implement thread `thr_xjn9c9vypu`.

## Timeline of reviews vs. pushes

| When (MDT) | Event | Reviewed? |
|---|---|---|
| 9/21 11:15–11:56 | `implement` runs `review --fix` round 1 (commit `f1d027f1`) | yes, but **no run record written** |
| 9/21 14:54 | Acceptance test finds Fabric family record lacks the child's numeric id; adds `DependentPatientLookup` (`dad8ab3`, 193 lines, 9 files) | **no** |
| 9/21 15:09 | Draft PR #980 opened on `dad8ab3` | |
| 9/22 09:01 | David approves `dad8ab3`; both of his real findings are in the unreviewed commit | |
| 9/22 10:17 | Remodel to `FabricPatient`/`FabricVisit` pushed (2 commits, ~1000 lines) | **no** |
| 9/22 10:26–10:42 | Jeremy's first review pass (mutual exclusion, backfill, empty-table migration) | |
| 9/22 10:36 | `review --fix` round 2 lands `dd09d6a`, fixing those same three | found 10 min after the human did |
| 9/22 11:57 | Jeremy requests changes; blocking item is the provisioning fan-out | |

## Each human comment vs. the pipeline

| # | Reviewer | Comment | Pipeline | Bucket |
|---|---|---|---|---|
| 1 | David | Family list re-fetched per child; cache it | Round 2 saw the lookup under the lock, recorded it as "pre-existing design, one-time cost per child", deferred | **misjudged** |
| 2 | David | Rescue `Errors::NotFound` on the per-member read | never raised | **lens gap: external-call failure paths** |
| 3 | David | Is the re-fetch under the lock necessary? | raised on #981 as pre-existing; author defended | not a miss |
| 4 | Jeremy | Validate `patient_id` xor `guardian_id` | round 2 caught it (two agents), fixed 9 min after the comment | **sequencing** |
| 5 | Jeremy | Namespacing nit | raised on #981 as nit | not a miss |
| 6 | Jeremy | Don't pass `auth`/`client` as dependencies | never raised | **lens gap: object design** |
| 7 | Jeremy | Timeouts belong in the client | never raised; six files defined the same two constants | **lens gap: duplication** |
| 8 | Jeremy | `self.fetch` wrapper redundant | never raised | object design (nit) |
| 9 | Jeremy | Worth retry logic? | never raised | **lens gap: external-call resilience** |
| 10 | Jeremy | Backfill `individual_uuid` for existing patients | round 2 caught it concurrently | **sequencing** |
| 11 | Jeremy | Migration assumes `fabric_visits` empty | round 2 caught it concurrently | **sequencing** |
| 12 | Jeremy | Service-object chain, quadratic lookup, merge into one PORO (blocking) | same as #1 | **misjudged** |
| 13 | Jeremy | Resolver should be a class method on `FabricPatient` | never raised | object design |
| 14 | Jeremy | `auth`/timeouts in the initializer | never raised; the PR added a 6th method to a pre-existing per-call pattern | object design, "extending a smell" |
| 15 | Jeremy | Pass ids, not the visit hash | never raised | object design (nit) |

Tally: 2 not misses, 3 found by the pipeline but after reviewers were already reading,
1 finding seen and misjudged (raised twice by humans, the blocking one), 8 never raised
(2 external-call resilience, 6 object design).

## Why each bucket happened

**Sequencing.** Two pushes went out without a review between the last review and the push.
The pipeline has no rule that a push must come from a reviewed SHA, and `implement` runs its
review at step 5, before the acceptance-test and E2E fixes that step 6/7 and the human steer
produce.

**Misjudged fan-out.** The round-2 record deferred the finding as "pre-existing design (the
lock exists to cover the Fabric create call); lookup adds one-time cost per child". The lock
was pre-existing; the list-plus-read-siblings loop inside it was new in `dad8ab3`. Pre-existing
was applied to the enclosing construct, not to the lines. The cost was stated as a phrase, not
as a formula in N (N list calls + up to N² member reads on first launch), so nobody could
check the arithmetic. `N-PLUS-ONE-QUERY` is scoped to database access and never looks at an
HTTP client called in a loop, let alone a service object that calls a service object that
loops.

**Never raised: external-call resilience.** No lens asks, for a new call to a vendor client,
what happens on 404 mid-way through a multi-call lookup, on 5xx or a dropped connection, and
whether a retry is safe (read) or not (write). `EMBEDDED-INTEGRATION-SECURITY` covers auth and
data exposure, not failure paths.

**Never raised: object design.** Six of Jeremy's comments are about where things live:
credentials and budgets passed on every call instead of held by the client, the same constants
in six files, a wrapper class method around a one-method instance, three service objects that
share no state, a lookup service whose only subject is one model, a payload hash where two ids
would do. `SEPARATION-OF-CONCERNS` is about layers (controller/service/model),
`CLARITY-SIMPLICITY` about branching and naming, `EXTENSIBILITY` about open/closed. None of
them ask "is this the right object, and does its signature leak how it works?"
`SEPARATION-OF-CONCERNS` does list "Duplication Signals" and still did not fire on six copies
of `CONNECT_TIMEOUT`/`RESPONSE_TIMEOUT`.

**Record gaps.** Round 1 (inside `implement`) wrote no record. Round 2 wrote a fix-run record
with an auto-fixed table and a deferred list, not the per-lens findings table
`REVIEW-RUN-RECORD.md` requires, so there is no way to tell whether any lens raised retry,
404, or the quadratic shape and a later step dropped it. Round 2 also collapsed 31 lenses into
4 agents (architecture shared an agent with testing and domain) and skipped the gate's
re-review pass, both deviations from the pipeline text that the record does not flag.

## Ideas, ranked on the retro fix ladder

### Tooling / mechanics (most deterministic)

1. **Push only from a reviewed SHA.** Before any push in `implement` (the `pr` step and any
   later "push it"), compare HEAD to the newest `Final SHA` / `HEAD SHA` in
   `runs/` + `fix-runs/` for the branch. If they differ, run `review --fix` first. Would have
   caught #1, #2 (David's two) before the PR opened and #4, #10, #11 before Jeremy started.
2. **Every review round writes the review run record**, including rounds inside `review-fix`
   and inside `implement`. Make the fix-run record carry a required `Review records:` line
   listing the per-round `runs/` files, so a missing one is visible. Add `deferred` to the
   outcome vocabulary or forbid it: today it is neither `kept` nor `dropped` and escapes the
   falsifier list.
3. **Record the lens-to-agent mapping.** If lenses are grouped, the record says which lenses
   shared an agent. Rule: architecture lenses never share an agent with testing or domain,
   and a re-review is never replaced by "targeted specs".

### Structure (lenses and context)

4. **Widen `N-PLUS-ONE-QUERY` to remote calls**, or add `EXTERNAL-CALL-FANOUT`: any client
   call inside a loop, any service called per item that itself lists or iterates, and any
   budget loop that spends its budget on items already known. The finding must state calls as
   a function of N and say whether it is linear or worse.
5. **New lens `EXTERNAL-INTEGRATION-RESILIENCE`**: for each new vendor call, the 404 path
   (partial failure in a multi-call lookup), 5xx/transport path, retry only for idempotent
   reads and never inside a latency budget without saying so, timeouts owned by the adapter,
   and whether the caller can tell "vendor said no" from "vendor unreachable".
6. **New lens `OBJECT-DESIGN`** (API ergonomics and cohesion): config or credentials passed
   per call instead of at construction; identical constants in more than one file; `self.call`
   wrappers around one-method instances; service chains that share no state; a lookup or
   resolver whose only subject is one model; hashes passed where two ids would do. Mostly nits,
   with one rule that changes severity: **adding another instance of an existing pattern makes
   the pattern in scope**, so the sixth per-call `auth:` method is not pre-existing.
7. **Pre-existing is decided per line, not per construct.** New calls inside an old lock, new
   branches inside an old method, are new. Belongs in step 8 of `code-review/AGENTS.md`.
8. **Cost claims are formulas.** Any demotion or deferral on cost grounds writes the cost as
   `f(N)` with N named, so the record can be checked without re-reading the code.

### Feedback loop (turns this manual exercise into a verb)

9. **`review --calibrate <PR>`** (or a retro lens): after a PR merges, fetch the human review
   threads, join them against the run record, and classify each thread as caught / found late /
   misjudged / never raised, appending to
   `$GREYBEARD_DATA/output/code-review/{repo}/calibration.md`. Retro then promotes repeated
   "never raised" categories into lens or context changes. This thread did that by hand in
   about an hour.
10. **`context/REVIEWER-PRIORS.md` for care_platform**, seeded from #980 and #981 and grown by
    #9: rich models over resolver services; one object per job rather than a chain of service
    objects; the adapter owns its budgets and credentials; cache repeated vendor lookups within
    a request; rescue the vendor's 404 where a list can be stale.
