# Workflows

This directory contains AI agent workflows. Each workflow is a structured pipeline for a specific task.

## Available Workflows

| Directory | Purpose |
|-----------|---------|
| `code-review/` | Technical code review against generalized lenses and repo-specific context |
| `knowledge-extraction/` | Multi-phase pipeline to extract business logic into documentation |

## Workflow Conventions

Each workflow directory should contain:

```
{workflow-name}/
├── CLAUDE.md           # Workflow instructions and execution steps
├── {components}/       # Workflow-specific modules, phases, or lenses
└── output/             # Generated artifacts (if applicable)
```

### CLAUDE.md Requirements

Every workflow CLAUDE.md should include:
1. **Purpose**: What problem does this workflow solve?
2. **Inputs**: What does the workflow need to run?
3. **Outputs**: What artifacts does it produce?
4. **Execution**: Step-by-step instructions for running the workflow
5. **Components**: Description of subdirectories and their contents

## Adding a New Workflow

1. Create a new directory under `workflows/`
2. Add a `CLAUDE.md` with the sections above
3. Organize components into logical subdirectories
4. Update the root `CLAUDE.md` to list the new workflow

## Shared Resources

All workflows can access:
- `sources/` — Cloned repositories for domain knowledge
- `sketches/` — Draft ideas (read-only reference)
