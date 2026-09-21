# System notices

Things the tooling told the agent that a human should know.

## Signal
MCP server instructions announcing a deprecated endpoint or missing write scope; "requires authentication" on a server; sandbox denials on paths or hosts the task needed; permission-classifier refusals; hooks printing errors; version or config warnings on startup.

## How to count
One per distinct notice per thread. Quote the notice briefly and say whether the agent acted on it, worked around it, or ignored it.

## Summary line
`- **System notices:** {notice} → {acted | worked around | ignored}; {…} | none`

## Typical fix rung
Rung 1: the config change the notice is asking for. These are the cheapest suggestions in the workflow and usually high confidence from a single thread, because the source is the system, not a pattern.

## False positives
- Notices already resolved in a later thread in the same window.
- Informational banners with no action attached.
