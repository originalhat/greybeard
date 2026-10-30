# Check

Walk each criterion from intake as real use, through the interface picked in step 2, and report what actually happened. This is the checking half of testing. Exploration comes after.

## Agent

One subagent, model `sonnet`, with `../PERSONA.md`. Given: the numbered criteria, the change map, the interface and base URL for each surface, and the login and setup the criteria assume (a role, seed data).

## Per-Criterion Procedure

1. **State the goal.** In one sentence: who does this, and what done looks like for them.
2. **Translate to actions.** Restate the criterion as concrete steps and an observable result. In a browser, that means navigate, click, type, and select. For an API, it means requests and responses. For a job, it means trigger it and look where the result lands. If the criterion is too vague to translate, mark it `couldn't verify` and say why. Don't guess what it meant.
3. **Do it the way a user would.** Reach the feature from its normal entry point, not a typed URL, unless users really arrive by link. Use realistic data. Make it asymmetric, so swapped or misread fields show up: a day above 12 in dates, different first and last names, an amount with cents. Save the edge cases for exploration.
4. **Ask the deeper question.** "It said success" is not the check. Look for the outcome where the user would look next: the list it should appear in, the detail page, the total that should change, the email in the mail preview, the other party's view. Then reload, or query again, and check it is still there. In a browser, read state with `browser_snapshot` rather than assuming from the last action. A click can fail without any sign.
5. **Do it twice.** Repeat with slightly different data, or as an edit instead of a create. A flow that works once can still fail the second time.
6. **Record** one of:
   - `pass`: the observed result matches.
   - `fail`: it contradicts the criterion, with what was expected and what was seen.
   - `couldn't verify`: no observable result, or a blocker (an earlier failure, missing fixture data). State the blocker plainly.

## Discipline

- Test the criterion as written, against what a user or caller sees. Don't confirm that the "right" function ran.
- One failure doesn't stop the run, unless it blocks everything after it (for example, you can't log in). Then mark the rest `couldn't verify` with that reason.
- Screenshot or capture the response on every fail.
- Reset between independent criteria (a fresh page load, a new record). No criterion should pass or fail because of leftover state.
- Note anything odd you see along the way as a **lead** for exploration, even when the criterion passed.

## Output

```
{N}. {criterion, restated as the checked behavior}: pass | fail | couldn't verify
   {if fail or couldn't verify: expected, observed, and the steps that produced it}

Leads: {odd things noticed, one line each}
```

The results feed the report's **Check** section. The leads feed the first charters.
