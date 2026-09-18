# Context

Archetype-specific gotchas, patterns, and pitfalls that apply to common kinds of refactoring campaigns. These are **general** — they apply to any codebase doing this kind of work, not just any one repo.

Repo-specific learnings (file paths, class names, table specifics, codebase conventions) live separately under `$GREYBEARD_DATA/output/campaigns/{repo}/_learnings.md` so private context stays out of the public greybeard repo.

## Contents

| File | When to apply |
|------|---------------|
| `DOMAIN-REFACTOR-GOTCHAS.md` | Campaigns that namespace Ruby/Rails classes into a domain (e.g., move `Foo` to `MyDomain::Models::Foo`) |

## How the Planner uses these

`pipeline/01-planner.md` Step 2 checks this directory for archetype-matching context. The Planner picks the file whose name matches the campaign's pattern and reads it in full before writing the strategy. The gotchas inform the done criteria, the recipe steps, and the edge-case catalog.

## Adding a new archetype

When you finish a campaign of a new pattern (test coverage, design-system adoption, API version upgrade, dependency rewrite, etc.) and have learnings worth preserving, add a file here. Naming convention: `{ARCHETYPE-NAME}-GOTCHAS.md` in SHOUTING-KEBAB-CASE. Keep entries:

- **Generic** — no company/repo-specific identifiers
- **Concrete** — describe the pitfall, the symptom, and the fix
- **Predictive** — phrased so the Planner can use them to anticipate edge cases, not just diagnose them after the fact
