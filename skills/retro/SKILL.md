---
name: retro
description: >-
  Retrospective on how the agent has been working. Reads the bb threads since
  the last run, quantifies recurring friction (corrections, steers, retries,
  tool failures, time lost), and proposes improvements ranked by how
  deterministic the fix is: config and tooling first, skill mechanics next,
  prose rules in CLAUDE.md or AGENTS.md last. Nothing is applied without
  approval. Use when the user says "retro", "/retro", "retrospective", "what
  should we improve", "review recent threads", or when a scheduled automation
  runs it. Verbs: retro (run), retro walkthrough (approve one at a time), retro
  apply <ids>, retro reject <ids>, retro status. Needs the bb CLI.
---

# Retro

A retrospective over recent agent threads that turns recurring friction into
approved, versioned improvements.

**Trigger:** `retro` runs a retrospective over everything since the last run
(first run: 24 hours; `--days N` or `--since YYYY-MM-DD` to widen, capped at
14 days), then walks the suggestions one at a time for approve / skip / change.
That interactive walkthrough is the default; `--report-only` stops at the
report. `retro walkthrough` resumes a parked walkthrough in any thread. `retro
apply S-… [S-…]` and `retro reject S-… [reason]` act on ids directly. `retro
status` prints open suggestions and acceptance counts.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/retro/AGENTS.md`.

That file holds the five-phase `pipeline/` (gather → summarize → synthesize →
report → apply) and `templates/`. State, reports, design notes, and the
changelog live in `$RETRO_HOME` (default
`$GREYBEARD_DATA/output/retro/`). If that directory is inside a git repo, every
run and every applied suggestion is committed there. Point `RETRO_HOME` at a
**private** repo; reports describe internal threads.

**Scheduled use:** a bb automation whose prompt is
`[retro] /retro` runs the retrospective daily; the `[retro]` marker keeps its
own threads out of the next window. The spawned thread parks on suggestion 1;
the user approves by replying there, or runs `retro walkthrough` anywhere.
