# Clarifying questions

Questions that should not have been asked, and questions that should have been.

## Signal
Two directions:
- **Asked and unnecessary:** the agent ended a turn on a question the user answered with something the agent could have derived from the ticket, the code, the repo docs, memory, or a sensible default. The user's answer is short and impatient, or restates something already in the thread.
- **Not asked and needed:** the agent guessed on a genuinely open point (which of two designs, which environment, whether to include X) and the guess was corrected later.

## How to count
One per question or per missed question. For asked ones, record whether it was `necessary` or `derivable (from: {where})`. For missed ones, record what was guessed and what the correction cost (minutes, a rebuilt piece).

## Summary line
`- **Clarifying questions:** asked {N} ({n} derivable); missed {N} → {what was guessed} cost {…}`

## Typical fix rung
Derivable questions → rung 3 or 4: the skill reads the source that had the answer, or the fact goes in memory. Missed questions → rung 3: a decision checkpoint in the skill before the expensive step (the implement design-choice step is the model).

## False positives
- Questions the user chose to answer even though the agent offered a default and proceeded; that is fine.
- A question at a genuine product or scope fork. Those are the point.
- Questions asked at the end of finished work ("want me to also…") are offers, not blockers.
