# googlechart

**Stata wrapper for the Google Charts (Visualization API) library.**

<img width="958" height="734" alt="image" src="https://github.com/user-attachments/assets/80ead98d-605a-46d5-b073-db5c3f96a13f" />


`googlechart` is a sibling — not a replacement — for [sparkta2](https://github.com/ericbooth/sparkta2-stata). Both produce self-contained interactive HTML from Stata; they target different use cases.

|                            | sparkta2                  | googlechart                                       |
|----------------------------|---------------------------|---------------------------------------------------|
| **Renderer**               | D3 v7 (bundled inline)    | Google Charts (Google Visualization API)          |
| **Network at view time?**  | No — fully offline        | **Yes** — Google ToS forbids self-hosting loader.js |
| **Best for**               | LaTeX briefs, embargoed reports, county / district choropleth | Live dashboards, public web embeds, polished default tooltips, native filter dropdowns, searchable tables |
| **Chart types**            | choropleth, bivariate, hexbin, points (maps); bar2/line2/donut/divbar/barrace (charts) | column, bar, line, area, combo, pie, donut, scatter, bubble, geo, timeline, **searchable table**, histogram, divbar |
| **Geo resolution**         | Down to Texas counties + 1,018 school districts | Country and US-state level only |
| **Filter controls**        | Custom filters / sliders (d3) | Native `google.visualization.Dashboard` + `ControlWrapper`, plus a built-in free-text Search box on `type(table)` |
| **Theming**                | TX2036 brand + Montserrat via `tx2036style` | Same |

If your output must work offline (briefs, embargoed reports), use sparkta2. If it's a live web embed or an internal dashboard and you want chart types sparkta2 doesn't cover (combo, bubble with a Play button across years, geo, animated line, searchable table), use googlechart.
For a runnable gallery exercising every chart type, see [test_googlechart.do](test_googlechart.do).

## Supported chart types (v0.1)

`column` `bar` `line` `area` `combo` `pie` `donut` `scatter` `bubble` `geo` `timeline` `table` `histogram` `divbar`

- The `divbar` (Pew-style diverging stacked bar) type works around the absence of a native diverging mode in Google Charts: the wrapper sign-flips negative-side levels and stacks via `isStacked`, with custom axis ticks that display absolute values. Long item labels are auto-wrapped to ~50 chars.
- The `table` type ships with a free-text Search box, sticky header, alternating row stripes, and tabular-numeric monospaced cells. Add `tablesearch tableheadersticky` to opt in.
- The `pie` / `donut` types default to legend below + a square frame so the bounding card hugs the chart instead of leaving a wide empty band to the right.

## Install

There are three install paths, in order of preference for TX2036 users:

### A. Texas 2036 `_codeshare` (recommended for staff)

Already on the Stata adopath for users with the standard `profile.do` that points `adopath ++` at the team's `_codeshare/` Drive folder. No further setup needed:

```stata
which googlechart
help googlechart
```

### B. SSC-style install from a local clone (no _codeshare)

```stata
net install googlechart, from("/path/to/googlechart-stata-public") replace
which googlechart
```

The package ships `googlechart.pkg` and `stata.toc` for this purpose.

### C. `adopath ++` from a local clone

Cheap and reversible — does not install anywhere:

```stata
adopath ++ "/absolute/path/to/googlechart-stata-public"
which googlechart
```

**Important: use an absolute path, not `~`.** The `~` shorthand is not expanded inside the quoted shell arguments that `sparkta2_appendfile` (the helper that embeds the engine into the output HTML) passes to `cat`. A tilde path would silently emit an empty `<script></script>` block — the chart would never render. Either install via path A or B above (preferred), or expand `~` to its absolute form here.

## Quick start

```stata
* Stata data: one row per region, with a numeric metric.
collapse (mean) poverty_rate, by(region_n)

* Column chart with full TX2036 styling + Export menu + animate-on-scroll
googlechart poverty_rate, name(region_n) type(column)               ///
    tx2036style download datatable animate                          ///
    title("Texas regions: mean poverty rate")                       ///
    ylabel("Poverty rate (%)")                                      ///
    export("poverty_by_region.html")
```

Open the resulting HTML in any modern browser with network access. Hover for tooltips, click **Export ▾** for PNG/SVG/CSV download or "View data table".

For a runnable gallery exercising every chart type, see [test_googlechart.do](test_googlechart.do).

## Side-by-side comparison: do-file gallery vs Google Sheets

For internal users, there is a parallel Google Sheets template that mirrors the **first five chart-type examples** in the do-file (divbar → bar → line → pie → donut) using identical data and the same sequence. The intent is for new staff to open the gallery HTML and the Sheet side-by-side and see the same five examples in the same order, so they can pick the right tool for the next task. The Sheet is internal only (Drive-restricted); see your team lead for the link.

The do-file gallery (`test_googlechart.do`) writes its outputs in this order:

1. **divbar** — Pew-style diverging stacked bar (6 Likert items, full survey-item text)
2. **table (Likert long-form)** — companion to (1), free-text search across all rows
3. **bar (horizontal)** — Texas regions, on-bar data labels
4. **line** — multi-series trend 2018–2024
5. **pie** — Texas postsecondary enrollment by sector, legend below
6. **donut** — same data as (5), donut variant, legend below
7+. column / area / combo / scatter / bubble (with Play across years) / geo / timeline / regions table (searchable) / histogram

The Sheets template covers gallery sections 1, 3, 4, 5, 6 with identical numbers. The five-chart manual recipe is in the internal `INTERNAL_sheets_template.md` (in the Cursor development folder, not published).

## New options in this build (v0.1.1)

- `legendpos(top|right|bottom|left)` — explicit legend placement. Pie / donut default to `bottom`.
- `tablesearch` — adds a free-text Search box above the rendered `type(table)`. Filters rows by substring match across all columns; row count updates live.
- `tableheadersticky` — sticky table header on scroll.
- `directlabels` on `type(bar)` / `type(column)` — renders the value above each bar (annotation role, classic corechart only).
- `time(varname)` on `type(bubble)` — adds a Play button + range slider so bubbles animate across the time dimension.
- `animate` on `type(pie)` / `type(donut)` — Google Charts does not honor `animation.startup` for pie / donut (confirmed by Google's own docs and issue #330). The wrapper substitutes a CSS opacity fade on the chart `ready` event.

## Network requirement (read this)

The output HTML loads `https://www.gstatic.com/charts/loader.js` at view time, then fetches per-chart-type packages (corechart, geochart, controls, ...) lazily. This is required by Google's Terms of Service — the loader code cannot be self-hosted or bundled.

Consequences:
- The HTML is small (~10–20 KB before content), but won't render without internet.
- Texas county choropleth and school-district maps are NOT supported (GeoChart stops at US-state level) — sparkta2 is the right tool for sub-state Texas geography.

## Author and license

Authored by Eric Booth (Texas 2036), 2026. Built atop the Google Charts library, which is the property of Google LLC and subject to the Google Charts Terms of Service. This package is not affiliated with or endorsed by Google.

The Stata wrapper is MIT-licensed (see [LICENSE](LICENSE)).
