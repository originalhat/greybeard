# Linear Tickets

What the finish files (`pipeline/05-finish.md` section 4): one Linear issue per **defect** the run found and didn't fix, filed automatically, and one per **refactor** too big for a round, filed only after the human approves it in the report. Lightweight: someone triaging reads the title and the first paragraph and knows who is affected or what gets easier, and how sure we are.

## Where

| | Defect | Refactor |
|---|--------|----------|
| Team | PROD | PROD |
| Project | Defects (`https://linear.app/sana-health/project/defects-660ea7a5aebe`) | none (team backlog) |
| Labels | `improve-workflow` + the repo's label | `improve-workflow`, `tech debt` + the repo's label |
| Priority | by user impact (below) | Low, unless it unblocks a defect fix |

- **The repo's label:** care_platform → `care-platform`, origami_claims → `origami-claims`. Other repos: none.
- **No `Bug` label** on defects: the project already says it's a bug.
- The project's default status, no assignee, no relations (blocks / blocked-by). When two tickets share an underlying problem, mention the other ID in the description instead.
- **Defect priority:** High when users lose data or a message, or a clinical workflow silently fails; Medium when users see a wrong or missing result with a workaround; Low for rough edges, wording, and accessibility gaps with an alternative path.

## Defect

```markdown
**Needs validation first:** {what to check, e.g. "run X in a CP staging console" or "reproduce in the browser"}. {Only when it rests on reading the code, low confidence, or an unrun check. Omit otherwise.}

{1-3 sentences in user terms: who hits it, what they do, what goes wrong. No code.}

{Optional: **Product question:** {the call someone has to make}, when it's unclear the current behavior is wrong.}

{Optional: **Steps:** a short repro, when validate reproduced it.}

+++ Agent notes

- Found by: improve {run id}, {I-n | validate {report path}}
- Where: `{path:line}`, …
- Evidence: {review-record / duplicate / test-gap / reading / validate repro}
- Seen on main @ {sha}

+++
```

Title: what the user experiences, not the code (`Refused referral status changes look like nothing happened`, not `422 dropped in useReferralStatus`). A product question can be phrased as one (`Should Escape and Enter cancel and save the title editors?`).

## Refactor

```markdown
**Recommended approach:** {one PR | campaign}. {One sentence on why: "every step is a move with no behavior change, so specs and a before/after screenshot check cover it" | "it changes the contract at 40 call sites and needs review points between batches"}

{1-3 sentences: what is hard today for the people who work in this code, and what gets easier. No file walkthrough.}

+++ Agent notes

- Found by: improve {run id}, I-{n} (pattern `{name}`, {k} slices)
- Goal: {the candidate's `fix`}
- Scope: about {N} files, {N} sites; where: `{path}`, …
- First step already built: {I-m in {PR} | none}
- To start it: `implement "<goal>"` for one PR, or `campaign plan "<goal>" in {repo}`

+++
```

Title: what changes (`Split the care request and referral components into their own files`).

**The bar for a campaign is high** (`pipeline/03-record.md` section 3). Mechanical, behavior-preserving work is one PR however many files it moves.

## Rules

- **PHI-free.** Linear is not a BAA'd system. No member, patient, or provider names, IDs, DOBs, or production URLs. Describe data by shape.
- **One ticket per finding**, even when two rounds or validate found it twice.
