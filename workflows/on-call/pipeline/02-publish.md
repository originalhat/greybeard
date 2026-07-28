# Phase 2 — Publish

Publish the results of a concluded triage back to the live JIRA ticket. Run this **after** `triage` and after the engineer has reviewed the analysis. This phase **writes to the live ticket**, so every write requires explicit confirmation.

## Input

Ticket ID (e.g. `ER-1477`). The Eng Requests project key is `ER`.

## Steps

### Phase 2a — Load the analysis

- Load the triage analysis (from the session, or the saved audit entry / local notes). If none exists, tell the engineer to run `triage` first and stop.
- Identify artifacts the investigation generated — diagnostic CSVs, console scripts, charts. Check for references in the analysis and look in `/tmp/` for files named after the ticket.

### Phase 2b — Draft what will be published

Show the engineer, before writing anything:

1. **The comment body** — a concise, public-facing summary: one-line problem restatement, root cause (if found), and the proposed fix. Not the full internal analysis.
2. **The attachment list** — genuine artifacts a human or a future run needs (a diagnostic CSV, a generated console script, a chart, or the analysis markdown for same-ticket reference).

**PHI is acceptable in JIRA** — the tickets already contain it and a BAA is in place — so do not strip names, UUIDs, or identifiers from the comment or withhold a file on PHI grounds. (This is the one place PHI is allowed; the greybeard-data audit log is **not** — keep the two separate.)

Ask the engineer to confirm the comment text and the file list. Proceed only on explicit approval. Let them edit either first.

### Phase 2c — Publish (only after confirmation)

- **Post the comment** with `mcp__atlassian__addCommentToJiraIssue` using `cloudId: "sanabenefits.atlassian.net"` and `contentFormat: "markdown"`.
- **Attach each approved file.** The Atlassian MCP has no attachment tool — upload via REST with the same credentials used to download attachments:

  ```bash
  curl -s -L \
    -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
    -H "X-Atlassian-Token: no-check" \
    -F "file=@/tmp/<filename>" \
    "https://sanabenefits.atlassian.net/rest/api/3/issue/<TICKET-ID>/attachments"
  ```

  - The `X-Atlassian-Token: no-check` header is required or JIRA rejects the upload as suspected XSRF.
  - The form field must be `file`; repeat `-F "file=@..."` to attach multiple files in one call.

### Phase 2d — Confirm

Report the comment URL/ID and which files were attached. If any `curl` upload returned a non-2xx response, surface the error rather than reporting success.

## Guidelines

- Every write to the ticket needs explicit confirmation — never post or attach without it.
- PHI is acceptable in JIRA (BAA in place); do not strip identifiers or withhold files on PHI grounds.
- If the analysis is missing or empty, stop and point the engineer back to `triage`.

## Next

Run `capture` to record the PHI-free audit entry and update runbooks.
