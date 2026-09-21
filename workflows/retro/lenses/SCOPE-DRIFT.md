# Scope drift

Work outside the ask.

## Signal
Files touched, refactors done, cleanups made, or features added that the ticket or request did not include; the user saying "we don't need that here", "separate PR", "stay on the ticket"; a diff whose changed-file list is wider than the ask. Distinct from `DESIGN-OVERREACH`, which is building the asked thing too big; this is building things not asked for.

## How to count
One per tangent. Record what was done outside scope, roughly how big (files or minutes), whether the user kept it, and whether it caused rework (reverted, split out, review noise).

## Summary line
`- **Scope drift ({N}):** {tangent} ({N files | N min}) → {kept | reverted | split out}; …`

## Typical fix rung
Rung 3: the implementing or reviewing skill states scope at intake and lists out-of-scope observations in the closing summary instead of doing them (the "Not built" section is the model). Rung 5 for free-form threads, as a default: "note it, do not do it."

## False positives
- Changes required to make the asked change work (a helper the feature needs, a test fixture).
- Tangents the user explicitly approved mid-thread.
- Fixing a defect that blocked the task.
