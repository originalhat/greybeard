# Residue

What the thread left behind in the environment.

## Signal
Records created or changed while verifying (test patients, flags, drafts) not reverted; gems or packages added to explore; untracked files and directories (probe scripts, screenshots, `.playwright-mcp/`); worktrees, stashes, branches created as a fallback; migrations run against a shared local database; a checkout left on a different branch than it started on.

## How to count
One per item left, with where. Say whether the user noticed or asked about it.

## Summary line
`- **Residue:** {item} in {where}; {…} | none`

## Typical fix rung
Rung 3 when a specific skill's verification step leaves it (the skill cleans up its own data). Rung 2 for structural causes (a shared checkout; worktrees fix it). Some users do not want cleanup rules at all; check `state.json` for rejected residue suggestions before proposing one.

## False positives
- Deliverables: the branch, the commits, files the user asked for.
- Things the user said to leave in place.
