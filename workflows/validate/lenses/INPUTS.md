# Inputs

What users type, paste, pick, upload, or send, and what happens at the edges of what each value expects. Every value has variables inside it: its length, its format, its characters, and how it got there.

**Interfaces:** any. Form fields, query parameters, API request bodies, imported files.

## Signals

The change adds or edits a form field, a search box, a filter, an upload, a date or number control, an API parameter, or a validation rule.

## Moves

- **Goldilocks:** too small, too big, just right. Empty; only spaces; one character; the maximum; one past it. Try lengths around powers of 2 (255, 256, 1024). Those are common hidden limits.
- **Characters:** apostrophes and hyphens (O'Malley, Smith-Jones), accents (José), emoji, CJK, right-to-left text, `<b>tags</b>`, `'; --`. Put the special character at the beginning, the middle, and the end.
- **Numbers:** 0, negative, decimals, many decimals, very large, leading zeros (01234), a thousands comma, a currency symbol typed in.
- **Dates and times:** Feb 29, Feb 31, Dec 31 to Jan 1, far past, far future, end before start, a day above 12 (so day and month can't be swapped silently), near midnight, other time zones.
- **Multiple valid formats:** a phone as (555) 123-4567, 555.123.4567, or +1 555 123 4567; ZIP and ZIP+4; an email with a display name. Each should be accepted, or clearly rejected, and shown the same way afterward.
- **Violate the format rules:** a negative age, a 13th month, an NPI or ID one digit short, a file that is mostly right but missing a required column.
- **Input method:** type it, paste it, autofill it, drag it. Validation sometimes runs on one method and not another.
- **Hidden inputs:** URL parameters, hidden form fields, extra JSON keys, cookies, and local storage values the UI sets for you. Change them by hand.
- **Clear it:** save with every optional field filled, then edit and blank them. Old values that refuse to clear are a classic bug.
- **Files:** wrong type, zero bytes, large, a name with spaces and unicode, the same file twice.
- After each move, **look at where the value shows up later**. Check how it is stored and shown, not only whether it was accepted.

## Findings

- A value is accepted but saved or shown differently than entered (trimmed wrongly, truncated without notice, garbled, rounded).
- A valid real-world value is rejected (an apostrophe in a name, a leading-zero ZIP).
- An invalid value is accepted and breaks a later screen, report, or job.
- An optional value can't be cleared.
- The error message is missing, technical, or doesn't say how to fix the input.
- Client and server disagree: the form allows it, then the save fails with a generic error.

## False positives

- Strict validation the intent asked for.
- Odd but harmless display of truly absurd input, unless it breaks the layout or a report for other users.
