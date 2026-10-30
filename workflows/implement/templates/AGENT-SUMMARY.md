# {TICKET-ID}: {ticket title}

Repo: `{repo}` · Branch: `{branch}` · Final SHA: `{sha}` · {YYYY-MM-DD}

Written for whoever opens this ticket later to understand what was built and why. PHI-free: no member, dependent, or patient identifiers.

## What changed

1-3 sentences from the user's point of view: what they can do now, or what behaves differently.

## Why it was built this way

- The design chosen and the reason, in a sentence each.
- **Not built:** the alternative from step 2 and the one sentence on why it lost.
- Every decision taken on the human's behalf (step 6 of the pipeline), with what prompted it, and whether the human kept or changed it.
- Every steer or answer from the human, with what prompted it (`Asked to drop the feature flag and remove the code path instead`).
- Assumptions made where the ticket was silent.

## Where it lives

The few files or modules a future reader should open first, one line each on what they hold. Not a file-by-file walkthrough.

## How it was tested

The behaviors covered by tests, one line each, and which specs hold them. Anything verified by hand (render check screenshots, console checks) and anything left untested, with why.

## Review and QA

What the review found and what was fixed, and the scope of the re-review. What validate checked, the bugs it found and which were fixed, and anything left open. Link the review, fix-run, and validate record paths.

## Commits

| SHA | Message |
|-----|---------|
| `{short sha}` | {message} |

## Open items

What still needs a human, or `None`.
