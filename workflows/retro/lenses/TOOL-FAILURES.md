# Tool failures

Commands and tool calls that failed, and how the agent recovered.

## Signal
A Bash command with a non-zero exit, a `<sandbox_violations>` block, an MCP tool error, a permission-classifier denial, a hook error printed to stderr.

## How to count
One per failed call. For each: the command or tool (short), the error class — `sandbox` (filesystem or network denial), `auth` (token, keychain, OAuth), `missing` (binary, file, path), `args` (wrong usage), `env` (shell option, hook, wrong Ruby), `classifier` (permission denied by the auto-mode classifier), `other` — and the retry path: `sandbox off`, `other tool`, `user did it`, `fixed args`, `none`. Seven `gh` failures in one thread are seven occurrences.

## Summary line
`- **Failed commands / tools ({N}):** {cmd} → {class} → {retry}; {cmd} → {class} → {retry}`

## Typical fix rung
Rung 1 almost always: a sandbox exclusion or allow-list entry, an MCP endpoint, a settings env var, a shell config line. If the same failure has a rung-1 fix, do not propose a rule about retrying.

## False positives
- A failure inside the sandbox that succeeded when retried outside is `sandbox` friction, not a broken tool. Do not report the tool as broken; re-check tool state outside the sandbox before saying so.
- Expected non-zero exits (`grep` with no match, `diff` reporting differences, a test the agent meant to see fail).
- One-off network blips with a clean retry.
