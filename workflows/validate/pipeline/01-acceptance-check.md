# Acceptance Check

Drive the running app through the acceptance criteria resolved in `validate`'s intake step, one at a time, and report what actually happened.

## Agent

One subagent, model `sonnet`, with the `playwright` MCP tools. Given: the numbered criteria list, the app's base URL (from the launch step), and any login/setup context the criteria assume (a test account, seed data, a specific role).

## Per-Criterion Procedure

For each criterion:

1. **Translate to actions.** Restate the criterion as a sequence of concrete user actions (navigate, click, type, select) and an expected observable result (text on screen, an element's presence/absence, a URL change, a value). If the criterion is too vague to translate into a concrete action, mark it `couldn't verify` and say why — don't guess at what it probably meant.
2. **Drive it.** Execute the actions via the `playwright` MCP tools. Use `browser_snapshot` to read state rather than assuming from the last action alone — a click can fail silently.
3. **Judge the result.** Compare what's actually on screen (or in the network/console output, if the criterion is about an API response or an error state) against the expected result.
4. **Record it** as one of:
   - `pass` — observed result matches.
   - `fail` — observed result contradicts, with what was expected and what was actually seen.
   - `couldn't verify` — the criterion doesn't resolve to a checkable UI action (e.g. it's about a backend side effect with no visible surface), or the app couldn't reach a state where it could be tested (blocked by an earlier failure, a missing test fixture). State the blocker plainly.

## Discipline

- Test the criterion as written, not the implementation. Don't open dev tools to check that the "right" function ran — check what the user would see.
- One criterion's failure doesn't stop the run. Continue through the full list so the report is complete, unless the failure makes every subsequent criterion untestable (e.g. can't log in at all) — in that case, mark the rest `couldn't verify` with that reason and stop.
- Screenshot or snapshot on every fail, so the report can describe what was actually seen, not a paraphrase from memory.
- Reset to a clean state between independent criteria when the app supports it (reload, fresh navigation) — a criterion should not pass or fail because of leftover state from the previous one.

## Output

A list, one entry per criterion:

```
{N}. {criterion, restated as the checked behavior} — pass | fail | couldn't verify
   {if fail or couldn't verify: what was expected, what was actually seen, and the action sequence that produced it}
```

Feeds directly into `templates/VALIDATION-REPORT.md`'s Acceptance Criteria section.
