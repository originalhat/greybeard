# Validate Workflow

General-purpose QA for a change, done the way a curious human tester would do it. First **check** that the change does what it claims for a real user. Then **explore** at and around the change to find what nobody specified: odd inputs, impatient clicks, interrupted state changes, other roles, and the other places the change's data turns up.

Tested = checked + explored. `review` reads the code. `validate` uses the running software.

A browser is the default for anything with a UI. It is not required. An API is explored over HTTP, and a background job or a model rule through a local console or runner. The persona and lenses are the same either way.

## Directory Structure

```
validate/
├── AGENTS.md                    # You are here
├── PERSONA.md                   # Who the tester is, how they observe, and how they decide something is wrong
├── pipeline/
│   ├── 01-acceptance-check.md   # Check: each stated criterion, plus the core flow, done for real
│   └── 02-exploratory.md        # Explore: charter → session/debrief loop → confirm
├── lenses/                      # Exploratory heuristics: where to look and what to try
├── context/                     # Per-app knowledge: launch, logins, seed data, known quirks
└── templates/
    ├── VALIDATION-REPORT.md     # The printed report
    └── VALIDATION-RUN-RECORD.md # The durable record of charters, rounds, and outcomes
```

## Inputs

Triggered by **`validate <ticket | PR | branch>`**: a Jira ticket URL or ID, a GitHub issue URL, a GitHub PR URL, `<branch-name> in <repo-name>`, or pasted freeform requirements. Also triggered by "qa this", "exploratory test", "bug bash", "try to break this".

- **The change.** From a PR URL, resolve the repo and branch. Otherwise use the branch checked out in the target repo (`in <repo>`, else inferred from the ticket, else the current directory's repo), under `$GREYBEARD_DATA/sources/{repo}/`. Prefer the user's own checkout when it has the branch. Doesn't switch branches. Diff with three dots: `git diff origin/main...HEAD`. The diff tells the tester where to look. It never tells the tester what is correct.
- **The intent.** The ticket, the PR description, or both. Treat them as the author's claims about what users should experience.
- **The target repo's docs**: root `CLAUDE.md` / `AGENTS.md`, plus any `CLAUDE.md` or `README.md` on the path to a touched file.
- **Running software.** Local by default. `--url <base-url>` points at a non-production environment. **Never run against production**, and never open a production console. Exploration creates, edits, and deletes data.
- `--check-only`: run the check and skip exploration (steps 6 to 8). The fast path for re-running after a fix.
- `--rounds N`: the exploration round cap (default 4). `--exploratory` is still accepted; exploration is now the default.
- Tools: the `playwright` MCP for UIs; `curl` for HTTP APIs; the repo's local console or runner for jobs and model behavior; a project launch skill (e.g. `run`) or the repo's conventions to start the app; the GitHub MCP for PRs; the `atlassian` MCP for Jira tickets.

## Outputs

- A report per `templates/VALIDATION-REPORT.md`, printed at the end: the check results, then bugs ranked by user impact, then questions for the author, then what was and was not covered.
- A run directory at `$GREYBEARD_DATA/output/validate/{repo}/{YYYY-MM-DD}-{pr{n} | branch}/` with `report.md`, `record.md` per `templates/VALIDATION-RUN-RECORD.md`, and `screens/`.
- Never modifies code, never commits.

## Execution

### Model Tiers

- **Check (step 5):** Sonnet. A careful walk of stated behavior.
- **Charter and debrief (steps 6 and 7b):** the most capable model. Choosing where to look next is the judgment call that makes exploration good.
- **Sessions and confirm (steps 7a and 8):** Sonnet subagents.

### Steps

These steps are **strictly sequential**.

1. **Intake.** Resolve the input to the change, the intent, and a numbered list of checkable criteria. A ticket's acceptance criteria come first. A PR description's claims come next. When neither states checkable behavior, write the core flow as the one criterion: who uses this, and what done looks like for them. Ask only if even that can't be inferred. Read the diff, the repo docs, and `context/APPS.md` for this repo.
2. **Pick the interfaces.** For each surface the change touches, choose how a user, or a caller, meets it:
   - **UI:** the browser, through the `playwright` MCP.
   - **HTTP API:** `curl` against the local server, with the same auth a real client uses.
   - **Background job, scheduled task, model rule:** trigger it the way production does when you can (enqueue it, call the entry point from the local console or runner). Then observe the result where a user or operator would see it.
   - **Email, SMS, notifications:** the local mail preview or delivery log, never a real send.

   Before you drive anything that sends a message or calls an outside vendor, confirm the local environment routes it to a stub or a sandbox. If you can't confirm that, ask. Stop only if nothing in the change can be exercised locally, and say what it would take (a vendor sandbox, a device, seed data).
3. **Launch.** Use a project launch skill if one exists, else the repo's conventions. Log in with what `context/APPS.md` gives. If it gives nothing, ask once, then propose an `APPS.md` entry in the report.
4. **Change map.** Built once by the frontier model, used by every later step:
   - **Surfaces:** where users or callers meet the change, and through which interface.
   - **Entities:** the things the change creates, reads, updates, or deletes, with their key attributes and what they belong to or contain.
   - **States:** any status, lifecycle, or mode the change adds or touches, and the events that move between them.
   - **Data paths:** everywhere the change's data shows up: lists, detail pages, search, reports, exports, emails, admin views, logs, other systems. Search the repo for these. The diff does not show them.
   - **Ecosystem:** outside services, jobs, files, and other apps the change depends on.
   - **Never and Always:** the rules this change must not break. Draw them from the core capability, from qualities like accuracy and access, and from what would hurt a user most. For example, "a member never sees another member's data" or "a claim total always equals the sum of its lines".
5. **Check** (`pipeline/01-acceptance-check.md`). Walk each criterion from step 1 as real use, through the interface from step 2. Report each one as pass, fail, or couldn't verify, with what was observed. If the core flow is broken so badly that nothing else can be measured, report now and skip exploration.
6. **Charter** (`pipeline/02-exploratory.md`). Write the backlog of charters from the change map, the check results, and the lenses.
7. **Explore loop** (`pipeline/02-exploratory.md`). Repeat until a stop condition holds:
   - **7a. Session:** a fresh subagent runs the top charters.
   - **7b. Debrief:** follow up on bugs and leads, then reorder the backlog.
8. **Confirm** (`pipeline/02-exploratory.md`). Replay every finding cleanly and decide its scope.
9. **Report and record.** Write the report per `templates/VALIDATION-REPORT.md` and print it. Write the run record per `templates/VALIDATION-RUN-RECORD.md`. Write the record even when nothing was found. A clean run with its coverage listed is useful information.

## Components

### Persona (`PERSONA.md`)

The tester's mindset, how they observe, the user personas they switch between, and the oracles they judge against when there is no spec. Every check and session agent gets it. Tune it here.

### Pipeline (`pipeline/`)

- **01-acceptance-check.md**: turning a criterion into real use, and what counts as pass, fail, or couldn't verify.
- **02-exploratory.md**: charters, the session and debrief loop, stop conditions, and confirmation. The round cap and session budget are expected to change as real runs show over- or under-exploring. Tune them there.

### Lenses (`lenses/`)

Generalized exploratory heuristics, one area of risk per file, each with the signals that make it worth running and the interfaces it applies to. See `lenses/AGENTS.md`.

### Context (`context/`)

Per-app knowledge: how to launch, which logins and roles exist, seed data, and known quirks not worth reporting again. See `context/AGENTS.md`.

### Templates (`templates/`)

- `VALIDATION-REPORT.md`: the printed report.
- `VALIDATION-RUN-RECORD.md`: the durable record.

## Notes

- **Judge as a user, not as the code.** An agent may read the diff to find where to look. It may not read the implementation to decide that odd behavior is intended. If the result surprises a user or a caller, that is a finding or a question.
- **Throwaway data only.** Name anything created with a `qa-` prefix so it is easy to find and clean up. List it in the run record. Never use real member data.
- **Severity words are fixed**: `severe` (data loss, wrong money, access to what the user should not see, crash or dead end), `moderate` (wrong behavior with a workaround), `minor` (confusing but correct).
- **Report evidence, not a verdict.** "Two bugs lose typed notes" lets the reader decide. "Not ready to ship" does not.
- Handoff, not fix: a bug worth fixing goes back to `implement`, `review --fix`, or the author.
- `implement` doesn't run this itself. Chain them: `implement <ticket>` to build it, then `validate <ticket>` once the branch exists.
