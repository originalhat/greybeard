# Step 0: Production hotspots

**Who:** the parent, in preflight, once per run (also before `discover` and `improve status`)
**Input:** the repo name, the Datadog MCP
**Output:** `$GREYBEARD_DATA/output/improve/{repo}/hotspots.tsv`: the files behind the endpoints and jobs that take the most total time in production

Without this, slices follow churn and past review findings, which says nothing about what is slow. A slow endpoint whose code rarely changes would never be scouted. With it, `pick-slice.sh` adds each hotspot's weight (20 for the top file down to 1 for the 20th) to its score, and `--focus perf` anchors only on hotspot files.

## Read-only and aggregate

Only aggregate APM numbers leave Datadog: resource names, hit counts, and p95 latency. Never span tags, URLs with IDs, trace contents, or log lines. Datadog resource names are normalized (`patientapi::carerequestscontroller_index`), so they carry no member data.

## Services

| Repo | Datadog service | Env |
|------|-----------------|-----|
| care_platform | `care-platform` | `production` |
| origami_claims | `origami-medical` | `production` |

Another repo: find its service with a span aggregation grouped by `service`, add the row here, and say so in the report. No service, no hotspots: skip this step in one line.

## Query

Follow the Datadog MCP's own instructions first (skill discovery, then `execute_code`). This script returns the input rows for `map-hotspots.sh`, web endpoints and background jobs ranked by total time (hits × p95) over 7 days:

```javascript
import { client, v2 } from "@datadog/datadog-api-client";
const service = "{service}", env = "production", days = 7;
const m = new v2.MetricsApi(client.createConfiguration());
const from = Date.parse(dd.time.hoursAgo(24 * days)), to = Date.parse(dd.time.now());
const top = async (kind, op, count) => {
  const r = await m.queryScalarData({ body: { data: { type: "scalar_request", attributes: { from, to,
    queries: [
      { name: "hits", dataSource: "metrics", aggregator: "sum", query: `sum:trace.${op}.hits{service:${service},env:${env}} by {resource_name}.as_count()` },
      { name: "p95", dataSource: "metrics", aggregator: "max", query: `p95:trace.${op}{service:${service},env:${env}} by {resource_name}` },
    ],
    formulas: [{ formula: "hits * p95", limit: { count, order: "desc" } }, { formula: "hits" }, { formula: "p95" }],
  } } } });
  const cols = r.data?.attributes?.columns ?? [];
  const g = cols.find(c => c.type === "group"), d = cols.filter(c => c.type !== "group");
  return (g?.values ?? []).map((v, i) => [kind, v[0], Math.round(d[1].values[i] ?? 0), (d[2].values[i] ?? 0).toFixed(3)].join("\t"));
};
const [web, jobs] = await Promise.all([top("web", "rack.request", 25), top("job", "sidekiq.job", 15)]);
return [...web, ...jobs].join("\n");
```

Then, from the checkout:

```bash
printf '%s\n' "<the returned rows>" > "$TMPDIR/apm-rows.tsv"
${CLAUDE_PLUGIN_ROOT}/workflows/improve/scripts/map-hotspots.sh < "$TMPDIR/apm-rows.tsv" > $GREYBEARD_DATA/output/improve/{repo}/hotspots.tsv
```

`map-hotspots.sh` maps each resource to its controller or job file at `origin/main` and lists the ones it can't map on stderr. Framework classes (`rails::healthcontroller`, `activestorage::analyzejob`) are expected there. Record in `record.md` the date, the service, and the top three lines.

## When Datadog isn't reachable

Keep an existing `hotspots.tsv` younger than 14 days and say its age in one line. Delete an older one; stale hotspots point scouts at code that may already be fixed. `--focus perf` with no hotspots stops before round 1 and says why.

## Frontend

APM covers the server. Client render cost has no production signal here, so `client/` files gain no hotspot weight. `REACT-PERFORMANCE` still runs on client slices, and a client slice whose API endpoint is a hotspot gets that endpoint's evidence (01-slice section 2).
