# Thread Summary

What a summarizing subagent returns for one thread. One block per thread, this shape, nothing else. Numbers are exact counts from the log or `n/a`; never estimates.

```markdown
### {thread id} · {title} · {project} · {repo path or "personal workspace"}
- **Ask:** {what the user wanted, one or two sentences}
- **Outcome:** done | handed off | stalled | abandoned | in progress — {one clause on what that meant here}
- **Timing:** first result after {N} min · total {N} min · longest turn {N} min · user waited on agent {N} min
- **Corrections ({N}):** {one line each, the user's words quoted briefly, what the agent had wrong}
- **Steers ({N}):** {one line each; mid-turn guidance, not friction unless the same steer recurs across threads}
- **Failed commands / tools ({N}):** {tool or command} → {error class: sandbox, auth, missing, wrong args} → {retry: sandbox off | other tool | user did it | none}
- **Manual steps by the user ({N}):** {things the user did by hand that the agent could have}
- **Skills used:** {skill or slash command} → {ran clean | needed follow-up: what}
- **Design overreach:** {built more than asked? what, and how the user reacted} | none
- **Residue:** {records, files, gems, worktrees left behind} | none
- **System notices:** {MCP deprecations, auth failures, sandbox denials worth knowing} | none
- **New since last review:** {only when the thread was previously reviewed} | n/a
```

Rules the subagent follows: `bb thread log <id> --format minimal --all` for content, `--format json --all` for timestamps; a user line followed by `steer` is mid-turn guidance; a sandbox failure that worked when retried outside is sandbox friction, not a broken tool; no member names, identifiers, credentials, or test-data values anywhere in the block.
