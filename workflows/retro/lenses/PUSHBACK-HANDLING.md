# Pushback handling

What the agent did when the user disagreed with it.

## Signal
A user message that challenges a finding, a plan, or a claim: "was this pre-existing?", "I don't think that's right", "this only happened once?", "we don't need that". Then the agent's next move.

## How to count
One per pushback. Classify the response:
- `verified, conceded`: went and checked, the user was right, said so in a line
- `verified, held`: went and checked, the user was wrong, showed the evidence
- `folded`: conceded without checking
- `defended`: held the position without checking
Record which, and whether the position turned out right.

## Summary line
`- **Pushback ({N}):** "{user's challenge}" → {verified, conceded | verified, held | folded | defended} → {agent was right | wrong | unknown}; …`

## Typical fix rung
`folded` and `defended` are the problems. Rung 3 where a skill has a pushback step (code-review's author-reply handling is the model: name the test, go run it). Rung 5 for free-form work, written as "when challenged, check before answering."

## False positives
- Preference statements ("I'd rather use X") are steers, not pushback on a claim.
- Pushback the agent could not check (needs production data, another person). Note it as `could not verify` instead.
