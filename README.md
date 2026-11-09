# googlechart

**Stata wrapper for the Google Charts (Visualization API) library.**

Create a self-contained interactive HTML page, dashboard, or single embeddable iframe from any Stata dataset. Fourteen chart types, native filter dropdowns, animations, an interactive searchable table, and a Pew-style diverging stacked bar — all from a single command.

```stata
* Column chart with animate-on-scroll + Export menu
googlechart poverty_rate, name(region) type(column)             ///
    download datatable animate                                  ///
    title("Texas regions: mean poverty rate")                   ///
    ylabel("Poverty rate (%)")                                  ///
    export("poverty_by_region.html")
```

Open the resulting HTML in any modern browser with internet access.

Live example site here: https://ericabooth.github.io/GoogleChart_Example_Site/ 

--

<img width="1082" height="633" alt="Screenshot 2026-06-29 at 1 02 27 PM" src="https://github.com/user-attachments/assets/06353fc4-0535-44e3-90a4-5a1ebf7e185d" />

`googlechart` is a sibling — not a replacement — for [sparkta2](https://github.com/ericabooth/Sparkta2_Example_Site). Use sparkta2 when you need a fully offline HTML (briefs, embargoed reports, sub-state geography). Use googlechart for live web embeds, dashboards, polished default tooltips, and chart types sparkta2 doesn't cover (combo, bubble-with-Play, animated line, searchable table, geo).

|                            | sparkta2                                                          | googlechart                                                       |
|----------------------------|-------------------------------------------------------------------|-------------------------------------------------------------------|
| **Renderer**               | D3 v7 (bundled inline)                                            | Google Charts (Visualization API)                                 |
| **Network at view time?**  | No — fully offline                                                | **Yes** — Google's ToS forbids self-hosting `loader.js`           |
| **Chart types**            | bar2, line2, donut, divbar, barrace, hexbin, choropleth (county / district), bivariate, points | column, bar, line, area, combo, pie, donut, scatter, bubble, geo, timeline, **searchable table**, histogram, divbar |
| **Geo resolution**         | Country, state, county, school district                           | Country, US-state level only                                      |
| **Filter controls**        | Custom d3-based filters / sliders                                 | `filters()`: a dropdown or range slider per variable on every chart type, plus a built-in Search box on `type(table)` |

## Supported chart types

`column` `bar` `line` `area` `combo` `pie` `donut` `scatter` `bubble` `geo` `timeline` `table` `histogram` `divbar`

- `divbar` (Pew-style diverging stacked bar) sign-flips negative-side levels and renders via Google's `isStacked` so a neutral level can centre on the zero line. Long row labels auto-wrap to ~50 chars.
- `table` ships with a sticky header, alternating row stripes, and tabular-numeric monospaced cells. Add `tablesearch` for a free-text Search box. The header is sticky whether or not you give `tableheadersticky`, which is accepted for compatibility.
- `pie` / `donut` default to legend below + a square frame so the bounding card hugs the chart instead of leaving an empty band of right-side legend space. Override with `legendpos(top|right|left|none)`; `legendpos()` applies to pie and donut.

## Install

Requires Stata 17 or newer.

The package is self-contained — `googlechart.ado`, the helper ado files, the engine, and the helpfile install together. No external Stata dependencies.

```stata
net install googlechart, from("https://raw.githubusercontent.com/ericabooth/googlechart-stata-public/main/") replace force
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

- The HTML holds your data and the package's own drawing code (about 75 KB before the data), but not the Google Charts library, so it won't render without internet access.
- Texas county choropleth / school-district maps are NOT supported by Google's GeoChart (it stops at US-state level). Use sparkta2 for sub-state US geography.

## Colors and the internal house style

Colors come from `scheme()`: `default` (Google Charts' standard series colors, used when you omit the option), `blues`, `reds`, `greens`, `oranges`, `purples`, `rdbu`, `rdylgn`, and `viridis`. Geo charts default to `blues` and diverging bars to `rdbu`.

The `tx2036style` option and the `tx2036` palette are an internal house style used in the authors' own workflows at Texas 2036. They are off unless you ask for them, and you do not need them. With `tx2036style`, the page asks Google Fonts for the Montserrat font; if the font cannot load, the browser uses a system font and the chart still draws. No style files are needed on your computer.

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
    download datatable animate                                  ///
    title("Central Texas leads regional poverty rates")         ///
    ylabel("Poverty rate (%)")                                  ///
    export("01_column.html")
```

For a runnable gallery exercising every chart type, see [test_googlechart.do](test_googlechart.do) in this repository. `net install` does not copy it, so download it from here. [test_googlechart_filters.do](test_googlechart_filters.do) writes one `filters()` page per chart type and checks what each page holds.

<img width="1286" height="715" alt="Screenshot 2026-06-29 at 1 02 56 PM" src="https://github.com/user-attachments/assets/88dbb18e-5718-464e-929f-b9e4464da4ce" />

## Changelog

### v0.1.5

- **Fix: numbers kept only about 4 significant digits.** Values were written with Stata's default display format, so an ID of 123456790 became `1.235e+08` and -1234567.891 became -1234567.9. Numbers are now written at full precision: `float` variables at the precision a float holds (14.2 stays 14.2), other types so the value reads back exactly.
- **Fix: `set dp comma` produced a blank chart.** The page always uses a `.` decimal point now.
- **Fix: `$` and `` ` `` in string data were treated as macros**, so a label like `Revenue $M` lost text. String values, value labels and variable labels are now written as they are.
- **Fix: a value ending in a double quote stopped the command** with `type mismatch`, r(109).
- **Fix: line breaks, tabs, other control characters and `</script>`** in data or in `title()` left the chart blank. They are now escaped.
- **Checks:** `legendpos()` must be `top`, `right`, `bottom`, `left` or `none` (new); `innerradius()` must be greater than 0 and less than 1; `centerlevel()` must name one of the levels. Each gives a clear error, r(198), instead of being accepted silently.
- **Fix: `filters()` drew a blank chart** ("Invalid column label" / "One or more participants failed to draw()") for column/bar/line/area charts and tables, because the filter variables were never written to the page. Each row now carries its filter values; the page draws its own dropdown (string or value-labeled variable) or low/high range slider (other numeric), and on each change it filters the rows and builds the chart again. `filters()` now works with all fourteen types, with `over()`, `tooltipvars()`, labeled filter variables, and together with `tablesearch` (previously one or the other). The row count, **Download CSV** and **View data table** follow the filters. See `help googlechart##filtersdetail`; regression cases are in `test_googlechart_filters.do`.
- Docs: help example 5 (bubble) now puts the variables in the order its axis titles describe; corrected the page-size statement, the sticky-header sentence, and the location of `test_googlechart.do`.

### v0.1.4

- Options read the same on every Stata version (`tx2036style`).
- The authors' house style is opt-in only. The default palette is Google Charts' standard colors (geo: blues; divbar: rdbu). An unknown `scheme()` falls back to the default with a note.
- The page is assembled with Mata instead of the shell (`type`/`cat`); a failed copy now stops with an error.
- A leading `~` in `export()` is expanded by the package.
- With `tx2036style`, the page falls back to a system font if Montserrat cannot load.

### v0.1.3

- **Fix: `time()` slider printed the time variable's name twice.** On a `type(bubble)` Play/time control, the wrapper drew its own `<label>` *and* Google's `NumberRangeFilter` drew the same `filterColumnLabel`, so "year" appeared twice above the slider. The wrapper now leaves the single control label to Google.

### v0.1.2

- **Guard: `animate` + `directlabels` on `type(bar)` / `type(column)`.** The annotation-role column that `directlabels` adds makes Google Charts throw on `animation.startup`, leaving the chart blank. `googlechart` now detects this combination, drops `animate`, and prints a note — so you get a chart that draws instead of a page that silently fails. Use one or the other on these types.
- Documented that `time()` needs a **panel**: one row per entity per value of the time variable (e.g. 51 states × 10 years). A single cross-section gives the Play control only one frame and nothing moves.

### v0.1.1

- `legendpos(top|right|bottom|left)` — explicit legend placement. Pie / donut default to `bottom`.
- `tablesearch` — adds a free-text Search box above the rendered `type(table)`. Filters rows by substring match across all columns; row count updates live.
- `tableheadersticky` — sticky table header on scroll.
- `directlabels` on `type(bar)` / `type(column)` — value labels above each bar (annotation role, classic corechart).
- `time(varname)` on `type(bubble)` — adds a Play button + range slider so bubbles animate across the time dimension. Requires a panel (one row per entity per value of the time variable).
- `animate` on `type(pie)` / `type(donut)` — Google does not honor `animation.startup` for pie / donut. The wrapper substitutes a CSS opacity fade + scale-in on the chart `ready` event so the option is actually visible.

## Author and license

Eric A. Booth, Sr Researcher, Texas 2036 (eric.a.booth@gmail.com). 
MIT-licensed (see `LICENSE`). Built atop the Google Charts library; this package is not affiliated with or endorsed by Google.
