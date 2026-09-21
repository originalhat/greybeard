# Thread Summary

What a summarizing subagent returns for one thread. One block per thread, this shape, nothing else. Numbers are exact counts from the log or `n/a`; never estimates.

The block is a fixed header followed by **one line per lens**, in the order the lenses were listed, using each lens's own **Summary line** format. The lens files (`lenses/*.md` and `$RETRO_HOME/lenses/*.md`) define the signal, the unit, and the false positives for each line; follow them.

```markdown
### {thread id} · {title} · {project} · {repo path or "personal workspace"}
- **Ask:** {what the user wanted, one or two sentences}
- **Outcome:** done | handed off | stalled | abandoned | in progress — {one clause on what that meant here}
- **New since last review:** {only when the thread was previously reviewed} | n/a
{one line per lens, e.g.}
- **Timing:** first result after {N} min · total {N} min · longest turn {N} min · user waited on agent {N} min
- **Corrections ({N}):** "{user's words}" → {what was wrong}; …
- **Steers ({N}):** {gist}; …
- **Failed commands / tools ({N}):** {cmd} → {class} → {retry}; …
- **Manual steps by the user ({N}):** {action} ({asked | volunteered}); …
- **Repeated context ({N}):** {fact} (already in: {location | nowhere}); …
- **Skills used:** {skill} → {ran clean | needed: {what}}; …
- **Design overreach:** {built} instead of {asked}; cost {…} | none
- **Residue:** {item} in {where}; … | none
- **System notices:** {notice} → {acted | worked around | ignored}; … | none
- **Unverified claims ({N}):** "{claim}" → {caught by user | uncaught} → {true | false | unknown}; …
- **Sunk-cost streaks ({N}):** {approach} × {attempts} over {N} min → {ending}; …
- **Pushback ({N}):** "{challenge}" → {verified, conceded | verified, held | folded | defended} → {right | wrong | unknown}; …
- **Clarifying questions:** asked {N} ({n} derivable); missed {N} → {guess} cost {…}
- **Chat noise:** {N} of {M} assistant messages carried nothing actionable; longest run {N}
```

Rules the subagent follows: `bb thread log <id> --format minimal --all` for content, `--format json --all` for timestamps; a user line followed by `steer` is mid-turn guidance; a sandbox failure that worked when retried outside is sandbox friction, not a broken tool; a lens with nothing to report still gets its line with `none` or `0`; no member names, identifiers, credentials, or test-data values anywhere in the block.
