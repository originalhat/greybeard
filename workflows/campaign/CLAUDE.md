# Campaign Workflow

A multi-agent pipeline for executing large-scale, systematic refactoring campaigns — migrations, architectural transitions, coverage sweeps, and similar efforts that span multiple sessions and many files.

Unlike other Greybeard workflows that surface *problems the human doesn't know about*, this workflow executes on a *goal the human already has*. The human defines what "done" looks like in plain English; the pipeline defines scope, writes the recipe, tracks progress, and makes the changes.

## Directory Structure

```
campaign/
├── CLAUDE.md       # You are here
└── pipeline/
    ├── 01-planner.md       # Interpret goal, write recipe, set execution mode
    ├── 02-inventorier.md   # Enumerate in-scope items, assess current status
    ├── 03-coordinator.md   # Batch and prioritize, produce plan + state file
    ├── 04-executor.md      # Make the actual changes, commit per item
    ├── 05-verifier.md      # Check done criteria, update state
    └── 06-reviewer.md      # First-pass code review, auto-fix, summarize for human
```

Output lives at `../greybeard-data/output/campaigns/{repo}/{campaign-name}/`:
```
{campaign-name}/
├── .campaign-state.json    # Tracks progress and last-run SHA for incremental continue
├── campaign-strategy.md    # Recipe, done criteria, execution mode (written once by Planner)
├── campaign-inventory.md   # All in-scope items with current status (updated each continue)
└── campaign-plan.md        # Living work plan with batches and progress dashboard
```

## Inputs

- A target repository cloned under `../greybeard-data/sources/{repo}/`
- A campaign goal stated in plain English (e.g., "convert all JS components to TypeScript")
- Optional: existing knowledge-extraction output at `../greybeard-data/output/knowledge-extraction/{repo}/` (used by Planner for DDD-style campaigns)

## Outputs

Per-repo, per-campaign living records under `../greybeard-data/output/campaigns/{repo}/{campaign-name}/`:

- `.campaign-state.json` — progress counters, last-run SHA, batch number
- `campaign-strategy.md` — the recipe: done criteria, step-by-step approach, edge cases, execution mode
- `campaign-inventory.md` — complete item list with DONE / TODO / BLOCKED / IN-PROGRESS status
- `campaign-plan.md` — living work plan with batches, prioritization, and progress dashboard
- `batch-{N}-review.md` — first-pass code review summary for each completed batch

## Execution

### Starting a Campaign

```
campaign plan <goal> in <repo-name>
```

Example: `campaign plan "convert all JS components to TypeScript" in care_platform`

Runs phases 1–3 (Planner → Inventorier → Coordinator). Produces the full strategy, inventory, and plan. Does not make any code changes.

### Continuing a Campaign

```
campaign continue <campaign-name> in <repo-name>
```

Example: `campaign continue js-to-ts in care_platform`

Runs phases 4–5 (Executor → Verifier) against the current next batch, then re-runs the Coordinator to update the plan and state. This is the recurring heartbeat of an in-progress campaign.

Each continue run:
1. Confirms the previous batch's branch has been merged (or prompts the user to confirm)
2. Pulls latest `main` in the source repo
3. Creates a new branch: `campaign/{campaign-name}/batch-{N}`
4. Executes the next batch, one commit per item
5. Verifies done criteria, updates state
6. Outputs the updated progress dashboard

The user reviews and merges the batch branch before the next `continue`.

### Checking Status (Read-Only)

```
campaign status <campaign-name> in <repo-name>
```

Reads `.campaign-state.json` and `campaign-plan.md` to display current progress. Makes no changes.

## Model Tiers

- **Phase 1 (Planner):** Opus — requires judgment to interpret ambiguous goals and design a durable recipe
- **Phase 2 (Inventorier):** Sonnet — pattern matching and status assessment, runs in parallel
- **Phase 3 (Coordinator):** Opus — batching strategy requires understanding dependencies and priorities
- **Phase 4 (Executor):** Sonnet — applies a well-defined recipe, runs in parallel within each batch
- **Phase 5 (Verifier):** Sonnet — checks done criteria mechanically, runs in parallel
- **Phase 6 (Reviewer):** Opus — first-pass code review, applies all applicable lenses, auto-fixes unambiguous issues

## Steps

### campaign plan

1. **Plan** (one Opus agent): Run `pipeline/01-planner.md`. Interprets the goal, defines "done" criteria per item, writes the recipe, sets execution mode (autonomous vs. guided), catalogs known edge cases. Produces `campaign-strategy.md`.

2. **Inventory** (one Sonnet agent per segment, parallel): Segment the repo by the scope defined in `campaign-strategy.md`. Run `pipeline/02-inventorier.md` per segment. Each agent enumerates in-scope items, assesses their current status (DONE / TODO / BLOCKED), and estimates effort. Produces per-segment outputs merged into `campaign-inventory.md`.

3. **Coordinate** (one Opus agent): Run `pipeline/03-coordinator.md`. Reads strategy + inventory, groups TODO items into logical batches, prioritizes them, writes `campaign-plan.md` and `.campaign-state.json`.

### campaign continue

4. **Execute** (one Sonnet agent per item in batch, parallel): Run `pipeline/04-executor.md` against the next batch from `campaign-plan.md`. Each agent applies the recipe from `campaign-strategy.md` to its assigned item, commits the change.

5. **Verify** (one Sonnet agent per completed item, parallel): Run `pipeline/05-verifier.md`. Each agent re-reads the changed file and checks it against the done criteria. Marks DONE, NEEDS-REVIEW, or REVERTED (with reason). Updates `.campaign-state.json`.

6. **Review** (one Opus agent): Run `pipeline/06-reviewer.md`. Runs the full Greybeard code review against the batch branch diff. Auto-fixes unambiguous issues. Produces `batch-{N}-review.md` — a summary of findings, fixes applied, and anything requiring human judgment. This is the handoff to the human reviewer.

7. **Re-coordinate** (one Opus agent): Re-run `pipeline/03-coordinator.md` to incorporate verified results, update the plan, and prepare the next batch.

## Execution Modes

Set by the Planner in `campaign-strategy.md`, overridable by the user:

- **Autonomous**: Executor runs the full batch without human checkpoints. Right for rote migrations (JS→TS, dependency updates, test coverage).
- **Guided**: Executor completes one batch and pauses. User reviews the branch diff before the next `continue`. Right for architectural campaigns (DDD restructuring, design system adoption) where judgment calls arise.

## Knowledge-Extraction Integration

For DDD-style campaigns, the Planner checks for knowledge-extraction output at `../greybeard-data/output/knowledge-extraction/{repo}/`. If present:
- Reads domain records to understand intended bounded contexts and boundaries
- Reads ubiquitous language to inform naming conventions in the recipe
- References specific domain records as the authority on "what belongs where"

Run `extract knowledge from <repo-name>` before planning a DDD campaign if knowledge extraction hasn't been run yet.

## Campaign Naming

When starting a campaign, choose a short kebab-case name for the campaign directory and branch prefix. If not provided, the Planner will derive one from the goal.

Examples: `js-to-ts`, `design-system-adoption`, `ddd-claims`, `test-coverage`

## State File

`.campaign-state.json` tracks progress across sessions:

```json
{
  "repo": "care_platform",
  "campaign": "js-to-ts",
  "goal": "Convert all JS components to TypeScript",
  "execution_mode": "autonomous",
  "last_run_sha": "abc123...",
  "last_run_at": "2026-04-24T10:00:00Z",
  "current_batch": 3,
  "total_items": 87,
  "done": 34,
  "in_progress": 0,
  "todo": 48,
  "blocked": 5,
  "needs_review": 0,
  "notes": "Batch 2 complete. HOC components are blocked — see campaign-inventory.md."
}
```
