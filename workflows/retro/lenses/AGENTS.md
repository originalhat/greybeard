# Lenses

One lens per thing the retrospective looks for in a thread. Phase 2 hands every lens to the summarizing subagents; each lens produces one line in the thread summary. Phase 3 clusters within and across lenses and uses each lens's typical fix rung as a starting point on the fix ladder.

Two locations are read, in this order:

- `${CLAUDE_PLUGIN_ROOT}/workflows/retro/lenses/*.md` — general lenses, shipped with the workflow. Not specific to any team.
- `$RETRO_HOME/lenses/*.md` — private lenses for one user or team: a recurring local pain, a convention worth policing, a metric only this team cares about. Same file shape. A private lens with the same filename as a general one replaces it.

Each lens:

- Measures one thing and says how to count it. Units are what make magnitude lines comparable across threads.
- Is under 60 lines.
- Names its false positives. Most bad suggestions come from a lens counting something that was not friction.

## Available lenses

| Lens | Counts |
|------|--------|
| `CORRECTIONS` | Times the user said the agent got something wrong |
| `STEERS` | Guidance sent mid-turn; friction only when the same steer recurs |
| `TOOL-FAILURES` | Failed commands and tool calls, by error class and retry path |
| `WAITING` | Minutes the user spent waiting on the agent, and time to first result |
| `MANUAL-STEPS` | Things the user did by hand that the agent could have |
| `REPEATED-CONTEXT` | Context the user had to supply that the agent could have known |
| `SKILL-FOLLOW-UP` | Skills and slash commands that needed manual patch-up after running |
| `DESIGN-OVERREACH` | Built more, or bigger, than the ask |
| `RESIDUE` | Records, files, packages, worktrees left behind |
| `SYSTEM-NOTICES` | Deprecations, auth failures, sandbox denials the agent was told about |
| `UNVERIFIED-CLAIMS` | Results asserted without the command or check that would produce them |
| `SUNK-COST` | Streaks of the same failing approach instead of stepping back |
| `PUSHBACK-HANDLING` | When the user disagreed: verified and conceded, verified and held, folded, or defended |
| `CLARIFYING-QUESTIONS` | Questions that were derivable, and guesses that needed a question |
| `CHAT-NOISE` | Assistant messages carrying nothing actionable |
| `REPEATED-ROUTINE` | Routine done by hand that a skill or script should do; skills and scripts that existed but did not run |
| `SCOPE-DRIFT` | Work outside the ask, kept or reverted |
| `HANDOFF` | Threads that ended without a state a later session could resume from |
| `COMMS-REWRITES` | Drafts for other people the user rewrote before sending, by kind of rewrite |

## Adding a lens

1. Create `{NAME}.md` here (general) or in `$RETRO_HOME/lenses/` (private). Upper-case name, hyphens.
2. Sections, in order: one-line purpose, **Signal** (what in the log indicates it), **How to count** (the unit, what is one occurrence, what is not), **Summary line** (the exact line the subagent writes, with placeholders), **Typical fix rung** (1–5 on the ladder in `pipeline/03-synthesize.md`), **False positives**.
3. Add a row to the table above (general lenses only).
4. No change to the pipeline or templates is needed; phase 2 reads the directory.
