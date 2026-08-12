---
name: dashboard-build
kind: workflow
description: >
  Core workflow for building dashboards and reports with Dataface. Use when
  creating new dashboards, editing existing YAML, adding charts, writing
  queries, iterating on layout, duplicating or copying a dashboard that already
  exists in the project, or when the user says 'build a dashboard',
  'create a report', 'add a chart', 'write a query', 'duplicate this
  dashboard', 'make me a copy of these'. Covers the
  build-test-iterate cycle, parameterized queries, caching, and incremental
  development. Do NOT use for diagnosing errors after something breaks (use
  dataface-troubleshooting). Do NOT use for design decisions about
  chart types or layout patterns (use dashboard-design or
  report-design).
metadata:
  author: fivetran
---
# Building Dataface Dashboards

**`dft render` is how you deliver a dashboard** — call it and return its output. Do not skip it.

## Delivery discipline

- `dft render` delivers the dashboard — call it and let the result stand. Do not also paste the rendered output or the full YAML back as prose; that just duplicates the deliverable as an unreadable dump.
- Act, don't ask. Apply edits and render directly — do not ask for permission to do the work you were handed ("if you want, I can save this", "would you like me to…"). This bans permission-seeking, not commentary — see `dft skills analyst-runbook` for what to deliver alongside the render.
- Fail loud. If a tool returns an error, report it and either fix the input and call the tool again, or stop and say what's blocking. Never route around a failed tool by fabricating output, dumping query rows as a text table in place of a chart, or improvising a different format. A failed render is a failure to report, not to paper over.
- Never claim a render, query, or save succeeded unless the tool returned success. Never invent columns, tables, or data — if a schema or query call fails, fix it against the real schema.

## Previewing vs. saving a face

`dft render` works two ways: pass `yaml_content` to render YAML directly **without writing a file** (an ephemeral preview), or pass `path` to render a saved face. **Which one is the default depends on the surface you are running on — your host's instructions say which.** A terminal/CLI session is file-first (the saved face is the deliverable); an embedded chat or editor host previews ephemerally and lets the user save explicitly. Follow your host; don't assume.

These rules hold on **every** surface, regardless of the default:

- **Never silently append to or mutate an existing face the user did not name** (e.g. `overview.yml`). Editing someone's saved dashboard because it happened to be the nearest file changes state they never asked you to change.
- When a save is intended but no target is named, write a **new** face rather than folding into an existing one.
- **A direct instruction is work to do, not work to hand back.** When the user asks you to save, copy, or edit a file, do it rather than describing how they could. A preview-first default governs work you were *not* asked to save. **Scope is your host's to define** — how many files one request may touch, and where you may write, is a permission question your host's instructions answer; follow them, and don't infer a broader licence from this rule.

Build dashboards and reports **incrementally** — one chart at a time, validating at every step. Never one-shot an entire dashboard.

### Duplicating a face

Copy a dashboard with `your file-read tool` then `your file-write tool` to the new path — there is no copy verb and you don't need one. Never `extends:` (the copy stays coupled to the original) and never a rebuild from a render (inlines result data, loses the SQL).


## Companion Skills

- **`dft skills dashboard-design`** — chart-type, layout, and color decisions
- **`dft skills dashboard-replicate`** — reproducing an existing dashboard from a screenshot or export
- **`dft skills report-design`** — narrative reports (text + charts)
- **`dft skills dashboard-review`** — self-review checklist run at delivery
- **`dft skills dataface-troubleshooting`** — when something breaks

YAML field reference is `dft docs` (overview), `dft docs <topic>` (one
section in depth), and `dft docs -s "<query>"` (full-text search).


## Metadata Requirement

Fill `description` on every named object — agents downstream rely on it for context and search:

- `queries.*.description` — what the query returns and why it exists
- `charts.*.description` — what question the chart answers
- `variables.*.description` — how the variable should be used
- Layout objects (`rows`/`cols`/`grid.items`/`tabs.items`) — section intent when useful

Keep each description short and factual (one sentence).

Labels and titles are inferred from object keys, and schema defaults are applied automatically. Omit `label`, `title`, `input: auto`, `required: false`, and `visible: true` unless you are intentionally changing the inferred/default value.

## The Workflow

### Step 1 — Explore the Data

Explore the schema with `dft query SOURCE SQL` against the warehouse's
metadata views (e.g. `INFORMATION_SCHEMA.TABLES`, then
`INFORMATION_SCHEMA.COLUMNS` filtered to the tables you care about) before
writing any query. Never invent a table or column name you have not seen.

Use `dft search` when the user asks for something similar to an
existing dashboard or when you need validated query patterns to reuse. Reuse
returned dashboard paths and query names exactly; never invent file globs such
as `data/*.csv` or guess paths from memory.

Use `dft query SOURCE SQL` to verify cardinality and sample values before writing any YAML:

```sql
SELECT status, COUNT(*) FROM orders GROUP BY status;
```

**Do not skip this step.** Writing SQL against assumed column names is the #1 source of errors.

### Step 2 — Build One Chart

Write a minimal YAML with a single query and chart:

```yaml
source: my_profile
queries:
  revenue:
    sql: SELECT date, SUM(amount) AS total FROM orders GROUP BY date ORDER BY date
charts:
  revenue_trend:
    query: revenue
    type: line
    x: date
    y: total
rows:
  - revenue_trend
```

Then verify with two calls:

1. `dft query SOURCE SQL` — confirm the data shape and columns
2. `dft render` — compile + render to see the visual

### Step 3 — Iterate on That Chart

Adjust SQL, chart type, labels, colors. Run `dft render <path>` to see the visual result — queries are cached after first execution, so re-rendering is nearly instant.

### Step 4 — Add the Next Chart

Repeat steps 2–3 for each additional chart. One at a time.

### Step 5 — Compose the Layout

Once all charts work individually, arrange them in `rows:` / `cols:`. The layout is the easy part — getting the queries right is the hard part.

```yaml
rows:
  - cols: [kpi_revenue, kpi_users, kpi_orders]
  - cols: [revenue_trend, 2]    # 2 = column span
  - cols: [by_region, by_product]
```

Don't put a `title:` on every row. A section heading over already-labeled charts is repetition, not structure — group with proximity instead. Reach for a row `title:` only when the dashboard is becoming more of a narrative — when there's accompanying `text:` prose, or the heading genuinely says something the charts don't (a shared scope like "Last 30 days", a real mode boundary). A title with no text alongside it usually means the title and the sectioning weren't needed — drop it. (This is dashboard guidance — in a **report**, sections are good: narrative `## …` headings in `text:` blocks carry the prose between charts — see `dft skills report-design`.)

### Step 6 — Save the Final YAML (when saving applies)

Skip this step when you are previewing ephemerally — see "Previewing vs. saving a face" above; your host decides the default. On hosts that offer the user a Save control over the rendered preview (the Cloud chat, for example), saving an unprompted preview is the user's click — don't write that file yourself. That default does not apply when the user explicitly asked you to save, copy, duplicate, move, or rename something: an explicit ask is your authorization on every host, so carry it out. When saving applies, write the YAML to a **new** face under `faces/` (never silently fold into an existing one) with your normal file-edit mechanism, then:

```bash
dft validate faces/finance/revenue-overview.yml
```


Fix any errors `dft validate` reports, then re-run until it passes.

**YAML style:** write block style — one key per line. Avoid JSON-like inline flow maps (`{ type: bar, x: month }`); they read and diff worse than indented blocks. Inline arrays (`y: [revenue, cost]`) are fine.

## Parameterized Queries — Use From the Start

Use `{{ variable_name }}` syntax for any configurable values, even during exploration:

```sql
SELECT * FROM orders WHERE region = '{{ region }}' AND date >= '{{ start_date }}'
```

Pass concrete values via the `variables` parameter when testing. When the query moves into dashboard YAML it works identically — and results are already cached.

**If you hardcode values during exploration and switch to variables later, the cache won't help because the SQL template changed.**

## Validate Early and Often

| Tool | When | What It Catches |
|------|------|-----------------|
| `dft query SOURCE SQL` | While drafting raw SQL | SQL errors, missing tables, wrong column names |
| `dft validate` | After every YAML edit | YAML schema errors, unknown fields, broken chart/query/layout references |
| `dft query FACE.yaml QUERY` | After saving YAML with named queries | Actual named-query columns and sample rows |
| `dft render` | Before delivery | Query execution, render errors, layout issues, misleading visuals |

These tools are fast. Use them after every change, not just at the end.

`dft render` also returns a `warnings` list alongside errors. Each has a stable code flagging either a **data** problem (all-null series, zero rows, a single temporal point, fan-out / re-aggregation) or a **design/visual** problem (a pie with too many slices, too many color or x categories, a missing currency/percent format, a mismatched shared y-axis). If `warnings` is non-empty, read each one and fix its cause — the query/data for data warnings, the **chart config** (chart type, encodings, formatting in the correct `style:` slot — see [Formatting Numbers](#formatting-numbers)) for design warnings — then re-render. Treat warnings like errors: don't deliver a dashboard while any remain unresolved (or say which one is a deliberate exception and why).

## Self-Review Before Delivering

Run the review skill as the final step before declaring the face done:

- Run `dft skills dashboard-review` before declaring a face done.

It orchestrates structural (dft validate) and visual (PNG + vision) passes and returns a ranked findings list. Fix each `blocker`, then re-run the review. Rendering and validation are cached — the loop is cheap.

## Data Requirements Per Chart Type

**Inline data** (no database) — columnar format only. Each row is an array, column names declared once:
```yaml
queries:
  my_data:
    columns: [month, revenue, churn]
    values:
      - [2025-01-01, 284000, 3.2]
      - [2025-02-01, 301000, 2.9]
```
**Do not use `rows: [{col: val}, ...]`** — that format is not supported. `type: values` is optional and changes nothing; omit it.

Each chart type expects data in a specific shape. Dataface validates this and errors fast — no silent magic.

| Chart Type | Expected Data | Key Fields |
|------------|---------------|------------|
| `kpi`      | **Exactly 1 row** with a value column | `value` (column reference) |
| `line`     | Multiple rows, temporal x + numeric y | `x`, `y` |
| `bar`      | One row per category, numeric y       | `x`, `y` — categorical x auto-flips to horizontal; override with `style.orientation: vertical` only when needed |
| `area`     | Multiple rows, temporal x + numeric y | `x`, `y` |
| `scatter`  | Multiple rows, both x and y numeric   | `x`, `y` |
| `pie`      | One row per segment (pre-aggregated)  | `theta` (numeric) + `color` (category) |
| `heatmap`  | One row per cell (pre-aggregated)     | `x`, `y`, `color` |
| `table`    | Any number of rows and columns        | Per-column format under `style.columns.<column_name>.format` (dict keyed by column — not a list) |

**Critical rules:**

- **KPI charts require exactly 1 row.** Aggregate to a single row: `SELECT SUM(amount) AS total FROM orders`. Multiple KPIs need separate single-row queries (or one query with multiple columns).
- **Pie and heatmap expect pre-aggregated data.** Use `GROUP BY` in the query. Dataface does NOT aggregate for you.
- **Don't mix metrics with very different magnitudes on one y-axis.** Metrics like churn (2–7%) and NRR (90–110%) on a shared axis will crush the smaller series flat. Use separate charts instead — there is no dual-axis support.
- **Multi-series line/bar/area: use `y: [col1, col2, col3]`.** Pass a list of column names to `y:` for multiple series on the same axis. Use `layers:` directly on a `bar`/`line`/`area`/`scatter` chart only when layers need different chart types (e.g., bar base + line overlay).
- **Bar `color` creates grouped bars.** Setting `color` to a different field than `x` allocates one sub-band per color value per x-band. If each x-value belongs to only one color group (e.g. each person is in one team), all other sub-bands are empty and every bar is razor-thin. Only use a different `color` field when each x-value truly has multiple rows with different color values. Otherwise set `color` to the same field as `x`, or omit it.

## Formatting Numbers

Dataface does not auto-detect format from column names at compile time. Set formatting explicitly wherever the number type matters — **in the slot for that chart family**, not at chart root.

### Where format goes

| Chart family | YAML slot | Example |
|--------------|-----------|---------|
| `line`, `bar`, `area`, `scatter`, `heatmap` | `style.number_format` (or `style.axis_y.format`) | `style.number_format: currency_whole` |
| `kpi` headline value | `style.value.format` | `style.value.format: currency_whole` |
| `kpi` support delta | `support.format` | `support.format: percent_delta` |
| `table` column | `style.columns.<col>.format` | `style.columns.revenue.format: currency_whole` |

**Never** put `format:` at chart root on `line` / `bar` / `area` / `scatter` / `kpi` — compile rejects it (`ERR-EXTRA-FIELD`).

Cartesian example:

```yaml
charts:
  monthly_sales_trend:
    type: line
    query: sales_by_month
    x: month
    y: won_amount
    style:
      number_format: currency_whole
```

Table example:

```yaml
charts:
  pipeline_table:
    type: table
    query: deals
    style:
      columns:
        amount:
          label: Amount
          format: currency_whole
          align: right
```

Named presets (prefer these over raw D3 strings):

| Preset | Example output | Notes |
|--------|---------------|-------|
| `integer` | `1,234` | |
| `currency_whole` | `$1,234` | |
| `currency_compact` | `$1.2M` | |
| `percent` | `2.3%` — input is decimal fraction (0.023) | line/bar/area/scatter via `style.number_format` |
| `percent_number` | `2.3%` — input is whole-number percent (2.3) | **KPI only** (`style.value.format`) |
| `percent_delta` | `+2.3%` — input is decimal fraction | |
| `percent_number_delta` | `+2.3%` — input is whole-number (2.3) | **KPI only** |

**`percent_number` and `percent_number_delta` only work on `type: kpi`.** Using them on line/bar/area/scatter causes a render error. For those chart types use `percent` or `percent_delta` (decimal-fraction input) or omit formatting and accept axis defaults.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Building the entire dashboard in one pass | Build one chart at a time |
| Writing SQL without checking column names | Check INFORMATION_SCHEMA via `dft query SOURCE SQL` first |
| Hardcoding values during exploration | Use `{{ variables }}` from the start so the query cache survives |
| Skipping validation between changes | `dft validate` after every YAML edit |
| Too many charts (>8) the user didn't ask for | Split into multiple dashboards |
| Using chart-type names as keys in layout | `table:` or `bar:` as keys cause parse errors — use descriptive names like `revenue_table` |
| Referencing query names in layout | Layout references charts, not queries — create a chart that wraps the query |
| KPI query returns multiple rows | Use `SUM()`/`COUNT()`/`AVG()` to aggregate to 1 row |
| Pie with raw unaggregated data | `GROUP BY` in query to aggregate before charting |
| Putting `height:` or `aspect_ratio:` under `style:` | Move them to chart root: `charts.my_chart.height: 400` — `style:` is paint only |
| Writing raw D3 format strings (`"$,.2s"`, `".1%"`) | Use a named preset (`currency_compact`, `percent`) — clearer and theme-consistent |
| Putting `format:` on a line/bar/area/scatter chart | Use `style.number_format:` — chart-root `format:` is rejected on cartesian chart families |
| Using `percent_number` or `percent_number_delta` on a line/bar/area chart | These are KPI-only — use `percent` or `percent_delta` instead (input must be decimal fraction 0–1) |
| Nesting `columns`/`values` under `sql:` for inline data | `sql:` is a string — inline data lives directly under the query name: `queries.my_data.columns: [...]` and `queries.my_data.values: [[...]]` |
| Using `type: values` + `rows:` for inline data | Not a valid query format — use `columns: [col1, col2]` + `values: [[row1val1, row1val2], ...]` directly under the query key |
| Putting `layers:` on a non-cartesian chart type | `layers:` is only valid on `bar`, `line`, `area`, and `scatter` — use `y: [col1, col2]` on any of those for simple multi-series without overlay marks |

## Rationalizations to Resist

| Excuse | Reality |
|--------|---------|
| "User asked for the whole dashboard at once" | Build incrementally anyway. Iterate to the result, don't one-shot it. |
| "I know what the columns are called" | You don't. Check INFORMATION_SCHEMA with `dft query SOURCE SQL`. |
| "Validation is slow, I'll do it at the end" | Validation is instant. Skipping it costs more time debugging later. |
| "It's just a quick chart, no need for variables" | Variables cost nothing and enable caching. Use them. |
| "15 charts is too many, I'll trim their list" | An explicit user ask wins. Suggest a split once, then build all 15. The 8-max default applies when the design is yours to choose. |

## Red Flags — STOP

- About to write SQL without having explored the actual schema first
- Building more than one new chart before validating the previous one
- Dashboard has more than 8 visualizations the user didn't ask for
- A chart exists without a clear question it answers
- Using hardcoded values that should be variables
- Delivering without running the self-review checklist
