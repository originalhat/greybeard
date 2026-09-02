---
name: design-audit
description: >-
  Audit a frontend repository for design consistency and produce a living design
  specification. Use when the user says "design audit <repo>" or "catch up
  design for <repo>". Inventories visual tokens (colors, typography, spacing,
  layout, components), captures screenshots at mobile/tablet/desktop viewports,
  analyzes inventory + screenshots against design lenses, and synthesizes a
  living design spec. The spec feeds the code-review DESIGN-CONSISTENCY lens.
  Supports incremental catch-up from the last audited SHA.
---

# Design Audit

Whole-repo design consistency assessment: inventory → screenshot → analyze → synthesize.

**Trigger:** `design audit <repo-name>` / `catch up design for <repo-name>`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/design-audit/CLAUDE.md`.

That file runs the 4-phase `pipeline/` against the design `lenses/`, writes
`design-spec.md` to `$GREYBEARD_DATA/output/design-audit/{repo}/` (default
`~/.greybeard-data/`), and keeps `.design-state.json` for incremental catch-up.
The spec is consumed by the code-review `DESIGN-CONSISTENCY-REVIEWER` lens.
