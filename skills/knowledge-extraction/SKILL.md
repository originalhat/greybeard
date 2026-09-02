---
name: knowledge-extraction
description: >-
  Extract business logic from a codebase into living documentation. Use when
  the user says "extract knowledge from <repo>" or "catch up knowledge for
  <repo>". Runs a 5-phase pipeline — crawl, extract, research, interrogate,
  synthesize — to produce domain records, ubiquitous language, and open
  questions. Not API docs: surfaces the decisions, constraints, and rules that
  explain why the code does what it does. Aligns terminology across related
  repos at integration points.
---

# Knowledge Extraction

Multi-phase pipeline that turns a codebase into a structured, living knowledge
base of business rules.

**Trigger:** `extract knowledge from <repo-name>` / `catch up knowledge for <repo-name>`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/knowledge-extraction/CLAUDE.md`.

That file drives the 5-phase `pipeline/` (crawler → extractor → researcher →
interrogator → synthesizer) and writes domain records, ubiquitous language,
and open questions to `$GREYBEARD_DATA/output/knowledge-extraction/{repo}/`
(default `~/.greybeard-data/`).

Output is consumed by the code-review `DOMAIN-KNOWLEDGE-REVIEWER` lens.
