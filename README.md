# googlechart

**Stata wrapper for the Google Charts (Visualization API) library.**

Create a self-contained interactive HTML page, dashboard, or single embeddable iframe from any Stata dataset. Fourteen chart types, native filter dropdowns, animations, an interactive searchable table, and a Pew-style diverging stacked bar — all from a single command.

```stata
* Column chart with brand palette + animate-on-scroll + Export menu
googlechart poverty_rate, name(region) type(column)             ///
    tx2036style download datatable animate                      ///
    title("Texas regions: mean poverty rate")                   ///
    ylabel("Poverty rate (%)")                                  ///
    export("poverty_by_region.html")
```

Open the resulting HTML in any modern browser with internet access.


<img width="1082" height="633" alt="Screenshot 2026-06-29 at 1 02 27 PM" src="https://github.com/user-attachments/assets/06353fc4-0535-44e3-90a4-5a1ebf7e185d" />


`googlechart` is a sibling — not a replacement — for [sparkta2](https://github.com/ericabooth/Sparkta2_Example_Site). Use sparkta2 when you need a fully offline HTML (briefs, embargoed reports, sub-state geography). Use googlechart for live web embeds, dashboards, polished default tooltips, and chart types sparkta2 doesn't cover (combo, bubble-with-Play, animated line, searchable table, geo).

|                            | sparkta2                                                          | googlechart                                                       |
|----------------------------|-------------------------------------------------------------------|-------------------------------------------------------------------|
| **Renderer**               | D3 v7 (bundled inline)                                            | Google Charts (Visualization API)                                 |
| **Network at view time?**  | No — fully offline                                                | **Yes** — Google's ToS forbids self-hosting `loader.js`           |
| **Chart types**            | bar2, line2, donut, divbar, barrace, hexbin, choropleth (county / district), bivariate, points | column, bar, line, area, combo, pie, donut, scatter, bubble, geo, timeline, **searchable table**, histogram, divbar |
| **Geo resolution**         | Country, state, county, school district                           | Country, US-state level only                                      |
| **Filter controls**        | Custom d3-based filters / sliders                                 | Native `Dashboard` + `ControlWrapper`, plus a built-in Search box on `type(table)` |

## Supported chart types

`column` `bar` `line` `area` `combo` `pie` `donut` `scatter` `bubble` `geo` `timeline` `table` `histogram` `divbar`

- `divbar` (Pew-style diverging stacked bar) sign-flips negative-side levels and renders via Google's `isStacked` so a neutral level can centre on the zero line. Long row labels auto-wrap to ~50 chars.
- `table` ships with a free-text Search box, sticky header, alternating row stripes, and tabular-numeric monospaced cells. Add `tablesearch tableheadersticky` to opt in.
- `pie` / `donut` default to legend below + a square frame so the bounding card hugs the chart instead of leaving an empty band of right-side legend space. Override with `legendpos(right)`.

## Install

The package is self-contained — `googlechart.ado`, the helper ado files, the engine, and the helpfile install together. No external Stata dependencies.

```stata
net install googlechart, from("https://raw.githubusercontent.com/ericabooth/googlechart-stata/master/") replace
which googlechart
help googlechart
```

The package ships `googlechart.pkg` and `stata.toc`, so Stata's installer picks up every file in one call. No manual `adopath` step is needed.

### Choosing a working folder for the output HTML

All `googlechart` commands write their HTML to the path you give in `export()`. There is no "working directory" the package itself manages — you control where the file lands. A common pattern in scripts:

```stata
local out "`c(pwd)'/charts"
capture mkdir "`out'"
googlechart ... , export("`out'/01_column.html")
```

## Network requirement (read this)

The output HTML loads `https://www.gstatic.com/charts/loader.js` at view time, then fetches per-chart-type packages (corechart, geochart, controls, ...) lazily. This is required by Google's Terms of Service — `loader.js` cannot be self-hosted or bundled into the HTML.

Consequences:

- The HTML is small (~10–20 KB before content), but won't render without internet access.
- Texas county choropleth / school-district maps are NOT supported by Google's GeoChart (it stops at US-state level). Use sparkta2 for sub-state US geography.

## Branding

The package ships a default Texas 2036 palette and Montserrat typography behind one option, `tx2036style`. Montserrat is loaded from Google Fonts at view time (same network requirement as the chart engine). The palette is:

| Token  | Hex      |
|--------|----------|
| Navy   | `#1B2D55` |
| Orange | `#D44500` |
| Link blue | `#2B6CB0` |
| Light bg | `#F5F7FA` |
| Muted gray | `#6C7A8D` |

You can pick any other palette with `scheme(blues | reds | greens | rdbu | rdylgn | viridis | ...)`. Without `tx2036style`, charts render in Google's default theme.

## Quick start

```stata
* Synthetic Texas regions data.
clear
input str10 region float poverty_rate
"North"    14.2
"East"     15.0
"South"    16.2
"West"     16.8
"Central"  18.9
end

googlechart poverty_rate, name(region) type(column)             ///
    tx2036style download datatable animate                      ///
    title("Central Texas leads regional poverty rates")         ///
    ylabel("Poverty rate (%)")                                  ///
    export("01_column.html")
```

For a runnable gallery exercising every chart type, see the included test file: [test_googlechart.do](test_googlechart.do).

<img width="1286" height="715" alt="Screenshot 2026-06-29 at 1 02 56 PM" src="https://github.com/user-attachments/assets/88dbb18e-5718-464e-929f-b9e4464da4ce" />




## New options in this build (v0.1.1)

- `legendpos(top|right|bottom|left)` — explicit legend placement. Pie / donut default to `bottom`.
- `tablesearch` — adds a free-text Search box above the rendered `type(table)`. Filters rows by substring match across all columns; row count updates live.
- `tableheadersticky` — sticky table header on scroll.
- `directlabels` on `type(bar)` / `type(column)` — value labels above each bar (annotation role, classic corechart).
- `time(varname)` on `type(bubble)` — adds a Play button + range slider so bubbles animate across the time dimension.
- `animate` on `type(pie)` / `type(donut)` — Google does not honor `animation.startup` for pie / donut. The wrapper substitutes a CSS opacity fade + scale-in on the chart `ready` event so the option is actually visible.

## Author and license

Eric A. Booth, Sr Researcher, Texas2036.org (eric.a.booth@gmail.com). MIT-licensed (see `LICENSE`). Built atop the Google Charts library; this package is not affiliated with or endorsed by Google.
