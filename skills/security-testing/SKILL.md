---
name: security-testing
description: >-
  Scan an entire repository for security vulnerabilities against 17 focused
  lenses. Use when the user says "pen test <repo>" or "catch up security for
  <repo>". Segments the repo into parallelizable units, scans each against the
  applicable security lenses, then consolidates, deduplicates, fact-checks, and
  ranks findings into a prioritized Critical/High/Medium/Low report. Supports
  incremental catch-up from the last scanned SHA.
---

# Security Testing

Whole-repo security assessment: segment → scan → consolidate → rank.

**Trigger:** `pen test <repo-name>` / `catch up security for <repo-name>`.

**Run:** execute `${CLAUDE_PLUGIN_ROOT}/workflows/security-testing/CLAUDE.md`.

That file runs the 3-phase `pipeline/` (segmenter → scanner → consolidator)
against the 17 lenses in `${CLAUDE_PLUGIN_ROOT}/workflows/security-testing/lenses/`,
and writes a prioritized report to `$GREYBEARD_DATA/output/security-testing/{repo}/`
(default `~/.greybeard-data/`). `.scan-state.json` enables incremental catch-up.
