---
name: on-call
description: >-
  Triage engineering on-call (ER) tickets and turn each resolution into durable
  knowledge. Use when the user says "triage", "triage <Jira ticket URL>", gives
  a bare ER ticket ID, or pastes an on-call problem description. Investigates
  the code, confirms the root-cause hypothesis with read-only snippets, and
  proposes a fix. Five verbs: triage, on-call publish, on-call capture, on-call
  curate, on-call sync. Builds a self-improving hierarchy of runbooks plus a
  PHI-free audit trail. Needs the atlassian (JIRA) MCP.
---

# On-Call

Triage on-call tickets and turn resolutions into durable runbooks + a PHI-free
audit trail.

**Trigger:** `triage <Jira ticket URL>` / `triage <ticket-id>` (e.g. `triage ER-1477`)
/ a pasted problem description, optionally `in <repo>`. The other verbs keep the
`on-call` prefix: `on-call publish|capture|curate|sync`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/on-call/CLAUDE.md`.

That file holds the 5-phase `pipeline/` (triage → publish → capture → curate →
sync), the `context/` authoring standard and escalation map, and `templates/`.
Runbooks and audit logs — the source of truth — live in
`$GREYBEARD_DATA/output/on-call/` (default `~/.greybeard-data/`), kept
PHI/PII-free; the JIRA ticket ID is the pointer to real identifiers.

**Setup:** the `atlassian` (JIRA) MCP is declared in the plugin's `.mcp.json`.
Wire it up (cloud `sanabenefits.atlassian.net`, project key `ER`) before running
against real tickets. Until then, `triage` works on a pasted description.
