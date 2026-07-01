*! test_googlechart.do  v0.1.1
*!
*!   Gallery of every googlechart type with brand styling.  Mirrors the
*!   sparkta2 gallery pattern: one HTML per example + a sparkta2_dashboard
*!   roll-up at the end.
*!
*!   Outputs land in `c(pwd)'/googlechart_demo_out/.
*!
*!   GALLERY ORDER (also the dashboard order) -- aligned with the
*!   Google Sheets template so the same five examples appear in the
*!   same sequence in both:
*!     1   14_divbar.html        Diverging stacked bar  (Likert, 6 items)
*!     2   12b_table_likert.html Likert long-form, searchable table   <- companion to 1
*!     3   02_bar.html           Bar (horizontal, data labels)
*!     4   03_line.html          Line  (multi-series, 2018-2024)
*!     5   06_pie.html           Pie   (legend below, square frame)
*!     6   07_donut.html         Donut (legend below, square frame)
*!     7+  column, area, combo, scatter, bubble (with Play), geo,
*!         timeline, regions table (searchable), histogram
*!
*!   SIDE-BY-SIDE WITH THE GOOGLE SHEETS TEMPLATE:
*!     The internal Sheets recipe (INTERNAL_sheets_template.md) mirrors
*!     gallery sections 1-7 using identical data.  A new user can open
*!     the gallery and the Sheet at the same time and watch the same
*!     numbers render two different ways (Stata + Google Charts vs.
*!     manual Sheets UI).  See the README for the side-by-side guide.

version 16.0
clear all
set more off

* googlechart lives at the root of _codeshare alongside sparkta2 (which
* is already on every TX2036 team member's adopath via the standard
* profile.do).  No `adopath ++' line is needed here -- findfile will
* resolve googlechart_engine.js to its absolute _codeshare path, which
* is what sparkta2_appendfile's shell-cat needs to embed the engine
* into the output HTML.
*
* If you're iterating on the source files in ~/Documents/Cursor/googlechart/
* without re-syncing to _codeshare yet, copy the four .ado / .js files
* to _codeshare's root by hand (or use the sync block at the top of
* googlechart-stata-public/test_googlechart.do which does this for you).

capture which googlechart
if _rc {
    display as error "googlechart not on adopath -- check _codeshare or your local clone."
    exit 199
}

local out "`c(pwd)'/googlechart_demo_out"
capture mkdir "`out'"

*=============================================================================
* DATASET 1 -- synthetic Texas regional data
*=============================================================================
clear
set obs 5
gen byte region_n = _n
label define regL 1 "North" 2 "East" 3 "South" 4 "West" 5 "Central"
label values region_n regL
label variable region_n "Region"

set seed 20260626
gen float poverty_rate    = 14 + 10*runiform()
gen float uninsured_rate  = 12 + 14*runiform()
gen float pop_thou        = 250 + 1500*runiform()
gen float life_expect     = 76 + 4*runiform()
gen byte urban            = (poverty_rate < 18)
label define urbanL 0 "Rural" 1 "Urban"
label values urban urbanL
label variable urban "Urban/Rural"

tempfile regions
save "`regions'", replace


*=============================================================================
* (1) COLUMN -- mean poverty by region
* SHEET MIRROR: Step 3, "Bar / Column", same 5 regions, vertical orientation.
*=============================================================================
googlechart poverty_rate, name(region_n) type(column)                          ///
      download datatable animate                                     ///
    title("Texas regions: mean poverty rate")                                  ///
    subtitle("Vertical bars (column), Texas 2036 palette, animate-on-scroll") ///
    ylabel("Poverty rate (%)")                                                 ///
    note("Source: synthetic data for googlechart v0.1.0 demonstration.")       ///
    width(900) height(560) noopen                                              ///
    export("`out'/01_column.html")


*=============================================================================
* (2) BAR -- horizontal, with tooltipvars + on-bar data labels
* SHEET MIRROR: Step 3, "Bar / Column", same 5 regions, horizontal orientation
* with on-bar value labels (the Sheets equivalent is Customize > Series >
* Data labels > "Above bar").
*=============================================================================
googlechart poverty_rate, name(region_n) type(bar)                             ///
    tooltipvars(uninsured_rate pop_thou)                                       ///
    directlabels                                                               ///
      download datatable downloadpos(below)                          ///
    title("Texas regions: poverty rate (horizontal)")                          ///
    xlabel("Poverty rate (%)")                                                 ///
    width(900) height(500) noopen                                              ///
    export("`out'/02_bar.html")


*=============================================================================
* DATASET 2 -- multi-series time-series for line/area/combo
*=============================================================================
clear
input str20 series double yr double y
"Texas"           2018 42.0
"Texas"           2019 43.1
"Texas"           2020 41.5
"Texas"           2021 42.8
"Texas"           2022 43.9
"Texas"           2023 44.5
"Texas"           2024 45.2
"ESC 13 (Austin)" 2018 46.5
"ESC 13 (Austin)" 2019 47.0
"ESC 13 (Austin)" 2020 46.1
"ESC 13 (Austin)" 2021 47.2
"ESC 13 (Austin)" 2022 48.0
"ESC 13 (Austin)" 2023 48.6
"ESC 13 (Austin)" 2024 49.3
"ESC 4 (Houston)" 2018 39.0
"ESC 4 (Houston)" 2019 40.4
"ESC 4 (Houston)" 2020 38.5
"ESC 4 (Houston)" 2021 39.1
"ESC 4 (Houston)" 2022 40.0
"ESC 4 (Houston)" 2023 40.6
"ESC 4 (Houston)" 2024 41.2
end


*=============================================================================
* (3) LINE -- multi-series trend, animate-on-view
* SHEET MIRROR: Step 5, "Line (Trend, 2018-2024)".  The Sheet uses the
* same 3 series and same year coverage.
*=============================================================================
googlechart y yr, over(series) type(line)                                       ///
      download datatable animate                                      ///
    title("Trend, 2018-2024 (multi-series line)")                               ///
    xlabel("Year") ylabel("% meeting standard")                                 ///
    width(980) height(560) noopen                                               ///
    export("`out'/03_line.html")


*=============================================================================
* (4) AREA -- same data, filled-area
*=============================================================================
googlechart y yr, over(series) type(area)                                       ///
      download datatable animate                                      ///
    title("Trend as filled-area chart")                                         ///
    xlabel("Year") ylabel("% meeting standard")                                 ///
    width(980) height(560) noopen                                               ///
    export("`out'/04_area.html")


*=============================================================================
* (5) COMBO -- bars + overlay line via combotypes()
*=============================================================================
googlechart y yr, over(series) type(combo)                                      ///
    combodflt(bars) combotypes("bars|bars|line")                                ///
      download datatable animate downloadpos(below)                   ///
    title("Combo: bars for Texas + ESC 13, line for ESC 4")                     ///
    xlabel("Year") ylabel("% meeting standard")                                 ///
    width(980) height(560) noopen                                               ///
    export("`out'/05_combo.html")


*=============================================================================
* DATASET 3 -- one-row-per-slice for pie/donut
*=============================================================================
clear
input str30 sector long enroll
"Public 4-year"  644000
"Public 2-year"  714000
"Independent"    162000
"Career schools"  86000
"Health-related"  19000
end


*=============================================================================
* (6) PIE chart -- legend below (default) for a square frame; animate=fade-in.
*     Pass smaller width(640) so the bounding card hugs the pie instead of
*     leaving a wide empty band on the right.  Add legendpos(bottom) is
*     redundant -- engine defaults to bottom for pie / donut now -- but
*     shown explicitly here for clarity.
* SHEET MIRROR: Step 4, second chart of the Donut + Pie pair.
*=============================================================================
googlechart enroll, name(sector) type(pie)                                      ///
      download datatable downloadpos(below) directlabels animate      ///
    legendpos(bottom)                                                           ///
    title("Public sectors enroll 84% of Texas postsecondary students")          ///
    width(640) height(540) noopen                                               ///
    export("`out'/06_pie.html")


*=============================================================================
* (7) DONUT chart -- same dataset, legend below, tight frame
* SHEET MIRROR: Step 4, first chart of the Donut + Pie pair.
*=============================================================================
googlechart enroll, name(sector) type(donut) innerradius(0.5)                   ///
      download datatable downloadpos(below) directlabels animate      ///
    legendpos(bottom)                                                           ///
    title("Texas postsecondary enrollment by sector (donut)")                   ///
    width(640) height(540) noopen                                               ///
    export("`out'/07_donut.html")


*=============================================================================
* DATASET 4 -- bivariate panel for scatter / bubble (county x year)
*   30 counties x 5 years = 150 rows.  Year is the time axis used by the
*   bubble play-button animation; scatter uses pov+life only.
*=============================================================================
clear
set obs 30
* NOTE: str10, not str8 -- "County 01" is 9 chars; str8 silently
* truncates to "County 0" and collapses all 30 counties into a handful
* of duplicates, which then breaks the bysort/yr replication below.
gen str10 county = "County " + string(_n, "%02.0f")
set seed 30
gen float pov_base  = 8 + 22*runiform()
gen float pop_k     = round(50 + 1000*runiform(), 5)
gen byte ur         = (pov_base < 16)
label define _ur 0 "Rural" 1 "Urban"
label values ur _ur
label variable ur "Urban/Rural"

* Replicate each county across 5 years, then add a mild year trend so
* the bubbles move (pov drifts down 0.5%/yr, life drifts up 0.2 yr/yr).
expand 5
bysort county: gen byte yr_off = _n - 1
gen int   yr   = 2020 + yr_off
gen float pov  = pov_base - 0.5 * yr_off + rnormal()*0.4
gen float life = 76 + 6*(1 - pov/30) + 0.2*yr_off + rnormal()*0.3
drop pov_base yr_off
label variable yr   "Year"
label variable pov  "Poverty rate (%)"
label variable life "Life expectancy (years)"


*=============================================================================
* (8) SCATTER -- pov vs life expectancy (latest year only)
*=============================================================================
preserve
keep if yr == 2024
googlechart pov life, name(county) type(scatter)                                ///
    tooltipvars(pop_k)                                                          ///
      download datatable animate                                      ///
    title("Life expectancy vs poverty rate (scatter, 2024)")                    ///
    xlabel("Poverty rate (%)") ylabel("Life expectancy (years)")                ///
    width(900) height(560) noopen                                               ///
    export("`out'/08_scatter.html")
restore


*=============================================================================
* (9) BUBBLE -- 3+ vars: x, y, color group, size, +Play across years
*=============================================================================
googlechart pov life, name(county) over(ur) sizevar(pop_k) time(yr) type(bubble) ///
    tooltipvars(pop_k yr)                                                       ///
      download datatable animate downloadpos(below)                   ///
    title("Bubble over time: counties move 2020-2024 (press Play)")             ///
    xlabel("Poverty rate (%)") ylabel("Life expectancy (years)")                ///
    width(900) height(560) noopen                                               ///
    export("`out'/09_bubble.html")


*=============================================================================
* DATASET 5 -- US state codes for geo chart
*=============================================================================
clear
* NOTE: str8 (not str4) -- "US-TX" is 5 chars; str4 silently truncates to
* "US-T" and the GeoChart fails to match any state code.
input str8 state_code double metric
"US-TX" 47
"US-CA" 51
"US-NY" 53
"US-FL" 49
"US-IL" 50
"US-PA" 52
"US-OH" 48
"US-GA" 46
"US-NC" 47
"US-MI" 50
end


*=============================================================================
* (10) GEO -- US state choropleth (resolution stops at us-states)
*=============================================================================
googlechart metric, name(state_code) type(geo)                                  ///
    georegion("US") georesolution("us-states")                                  ///
      download datatable scheme(blues)                                ///
    title("US states: example metric")                                          ///
    note("Note: GeoChart supports country + US-state level only.  For Texas county work, use sparkta2.") ///
    width(900) height(560) noopen                                               ///
    export("`out'/10_geo.html")


*=============================================================================
* DATASET 6 -- timeline (Texas legislative sessions, synthetic)
*=============================================================================
clear
input str30 session str11 start_s str11 end_s
"86th Regular (2019)"  "08jan2019"  "27may2019"
"87th Regular (2021)"  "12jan2021"  "31may2021"
"87th Special (2021)"  "08jul2021"  "02sep2021"
"88th Regular (2023)"  "10jan2023"  "29may2023"
"89th Regular (2025)"  "14jan2025"  "02jun2025"
end
gen double start_d = date(start_s, "DMY")
gen double end_d   = date(end_s,   "DMY")
format start_d end_d %td


*=============================================================================
* (11) TIMELINE -- Gantt swimlanes
*=============================================================================
googlechart, type(timeline) name(session)                                       ///
    startvar(start_d) endvar(end_d)                                             ///
      download datatable downloadpos(below)                           ///
    title("Texas legislative sessions, 86th-89th")                              ///
    width(980) height(420) noopen                                               ///
    export("`out'/11_timeline.html")


*=============================================================================
* DATASET 7 -- table + filters
*=============================================================================
use "`regions'", clear


*=============================================================================
* (12) TABLE -- interactive table with free-text search, sticky header,
*      monospaced numerics, and Texas 2036 styling.  Two variants written:
*        12a -- search + sticky on the regions dataset
*        12b -- search + sticky on the Likert long-form dataset (so the
*               user can scan all survey items + percentages quickly)
*=============================================================================
googlechart, type(table)                                                        ///
    tooltipvars(region_n poverty_rate uninsured_rate pop_thou life_expect urban) ///
    tablesearch tableheadersticky                                               ///
      download datatable downloadpos(below)                           ///
    title("Texas regions: searchable data table")                               ///
    width(980) height(420) noopen                                               ///
    export("`out'/12_table.html")

* 12b -- the same Likert dataset the divbar uses, but in raw long form,
* with extra companion columns (topic area, sample n, +/- margin) so the
* table is wide enough to demonstrate horizontal scroll.  This is the
* side-by-side table to keep open while discussing divbar findings.
preserve
clear
input str120 q str22 response double share str22 topic_area int sample_n double margin_pct
"K-12 investment on the right track"                                 "Strongly disagree" 18 "Education"        812  3.4
"K-12 investment on the right track"                                 "Disagree"          22 "Education"        812  3.4
"K-12 investment on the right track"                                 "Neutral"           14 "Education"        812  3.4
"K-12 investment on the right track"                                 "Agree"             29 "Education"        812  3.4
"K-12 investment on the right track"                                 "Strongly agree"    17 "Education"        812  3.4
"Local district uses its funding effectively"                        "Strongly disagree"  9 "Education"        812  3.4
"Local district uses its funding effectively"                        "Disagree"          18 "Education"        812  3.4
"Local district uses its funding effectively"                        "Neutral"           21 "Education"        812  3.4
"Local district uses its funding effectively"                        "Agree"             39 "Education"        812  3.4
"Local district uses its funding effectively"                        "Strongly agree"    13 "Education"        812  3.4
"Higher ed in Texas is affordable for most families"                 "Strongly disagree" 29 "Higher Ed"        796  3.5
"Higher ed in Texas is affordable for most families"                 "Disagree"          33 "Higher Ed"        796  3.5
"Higher ed in Texas is affordable for most families"                 "Neutral"           14 "Higher Ed"        796  3.5
"Higher ed in Texas is affordable for most families"                 "Agree"             18 "Higher Ed"        796  3.5
"Higher ed in Texas is affordable for most families"                 "Strongly agree"     6 "Higher Ed"        796  3.5
"Workforce training meets local employer needs"                      "Strongly disagree" 11 "Workforce"        805  3.4
"Workforce training meets local employer needs"                      "Disagree"          21 "Workforce"        805  3.4
"Workforce training meets local employer needs"                      "Neutral"           24 "Workforce"        805  3.4
"Workforce training meets local employer needs"                      "Agree"             33 "Workforce"        805  3.4
"Workforce training meets local employer needs"                      "Strongly agree"    11 "Workforce"        805  3.4
"Healthcare workforce sufficient in rural / underserved areas"       "Strongly disagree" 32 "Healthcare"       788  3.5
"Healthcare workforce sufficient in rural / underserved areas"       "Disagree"          31 "Healthcare"       788  3.5
"Healthcare workforce sufficient in rural / underserved areas"       "Neutral"           16 "Healthcare"       788  3.5
"Healthcare workforce sufficient in rural / underserved areas"       "Agree"             16 "Healthcare"       788  3.5
"Healthcare workforce sufficient in rural / underserved areas"       "Strongly agree"     5 "Healthcare"       788  3.5
"Water supply ready for 20-yr population growth"                     "Strongly disagree" 21 "Infrastructure"   811  3.4
"Water supply ready for 20-yr population growth"                     "Disagree"          28 "Infrastructure"   811  3.4
"Water supply ready for 20-yr population growth"                     "Neutral"           22 "Infrastructure"   811  3.4
"Water supply ready for 20-yr population growth"                     "Agree"             22 "Infrastructure"   811  3.4
"Water supply ready for 20-yr population growth"                     "Strongly agree"     7 "Infrastructure"   811  3.4
end
label variable q          "Survey item"
label variable response   "Response level"
label variable share      "Share (%)"
label variable topic_area "Topic area"
label variable sample_n   "n (respondents)"
label variable margin_pct "+/- margin (pp)"

googlechart, type(table)                                                        ///
    tooltipvars(q response share topic_area sample_n margin_pct)                ///
    tablesearch tableheadersticky                                               ///
      download datatable downloadpos(below)                           ///
    title("Likert long-form table (search across all 6 items + columns)")       ///
    note("Companion to the diverging stacked bar in section 1. Type a topic or response level to filter. Table is wider than the card -- scroll horizontally to see all columns.") ///
    width(980) height(420) noopen                                               ///
    export("`out'/12b_table_likert.html")
restore


*=============================================================================
* DATASET 8 -- histogram observations
*=============================================================================
clear
set obs 500
set seed 626
gen float score = 60 + rnormal()*15
gen str10 grade = cond(score < 70, "Below", cond(score < 85, "Approaches", "Meets"))


*=============================================================================
* (13) HISTOGRAM -- distribution of synthetic scores
*=============================================================================
googlechart score, type(histogram)                                              ///
      download datatable animate                                      ///
    title("Distribution of synthetic scores (n=500)")                           ///
    xlabel("Score") ylabel("Count")                                             ///
    width(900) height(560) noopen                                               ///
    export("`out'/13_histogram.html")


*=============================================================================
* DATASET 9 -- Likert survey items for divbar
*=============================================================================
clear
input str120 q str22 response double share
"Texas is on the right track when it comes to investing in K-12 public education" "Strongly disagree" 18
"Texas is on the right track when it comes to investing in K-12 public education" "Disagree"          22
"Texas is on the right track when it comes to investing in K-12 public education" "Neutral"           14
"Texas is on the right track when it comes to investing in K-12 public education" "Agree"             29
"Texas is on the right track when it comes to investing in K-12 public education" "Strongly agree"    17
"My local school district uses its funding effectively"                            "Strongly disagree"  9
"My local school district uses its funding effectively"                            "Disagree"          18
"My local school district uses its funding effectively"                            "Neutral"           21
"My local school district uses its funding effectively"                            "Agree"             39
"My local school district uses its funding effectively"                            "Strongly agree"    13
"Higher education in Texas is affordable for most families"                        "Strongly disagree" 29
"Higher education in Texas is affordable for most families"                        "Disagree"          33
"Higher education in Texas is affordable for most families"                        "Neutral"           14
"Higher education in Texas is affordable for most families"                        "Agree"             18
"Higher education in Texas is affordable for most families"                        "Strongly agree"     6
"Workforce training programs in my region meet local employer needs"               "Strongly disagree" 11
"Workforce training programs in my region meet local employer needs"               "Disagree"          21
"Workforce training programs in my region meet local employer needs"               "Neutral"           24
"Workforce training programs in my region meet local employer needs"               "Agree"             33
"Workforce training programs in my region meet local employer needs"               "Strongly agree"    11
"Texas should invest more in early childhood education before kindergarten"        "Strongly disagree"  7
"Texas should invest more in early childhood education before kindergarten"        "Disagree"          13
"Texas should invest more in early childhood education before kindergarten"        "Neutral"           18
"Texas should invest more in early childhood education before kindergarten"        "Agree"             36
"Texas should invest more in early childhood education before kindergarten"        "Strongly agree"    26
"Texas has enough nurses and physicians to serve rural and underserved areas"      "Strongly disagree" 32
"Texas has enough nurses and physicians to serve rural and underserved areas"      "Disagree"          31
"Texas has enough nurses and physicians to serve rural and underserved areas"      "Neutral"           16
"Texas has enough nurses and physicians to serve rural and underserved areas"      "Agree"             16
"Texas has enough nurses and physicians to serve rural and underserved areas"      "Strongly agree"     5
"Texas is prepared for water-supply challenges from population growth (20-yr)"     "Strongly disagree" 21
"Texas is prepared for water-supply challenges from population growth (20-yr)"     "Disagree"          28
"Texas is prepared for water-supply challenges from population growth (20-yr)"     "Neutral"           22
"Texas is prepared for water-supply challenges from population growth (20-yr)"     "Agree"             22
"Texas is prepared for water-supply challenges from population growth (20-yr)"     "Strongly agree"     7
end


*=============================================================================
* (14) DIVBAR -- Pew-style diverging stacked bar (Google Charts workaround)
* SHEET MIRROR: Step 2, "Diverging stacked bar (Likert)".  The Sheet
* recipe lists the same 6 items with the same percentages.  Sheets has
* NO native diverging mode, so the Sheet renders a plain stacked bar
* with the same colour palette; the divbar workaround here actually
* centres the neutral level on the zero line.
*=============================================================================
googlechart share, name(q) level(response) type(divbar)                         ///
    levelorder("Strongly disagree|Disagree|Neutral|Agree|Strongly agree")       ///
    centerlevel(Neutral)                                                        ///
      download datatable downloadpos(below)                           ///
    title("Texans on K-12 and higher-ed policy (Likert, divbar)")               ///
    subtitle("Pew-style diverging stacked bar via Google Charts sign-flip workaround") ///
    width(1100) height(620) noopen                                              ///
    export("`out'/14_divbar.html")


*=============================================================================
* GALLERY -- combine all 14 onto a single scrollable dashboard
*=============================================================================
capture which sparkta2_dashboard
if !_rc {
    * The sparkta2_dashboard prepends its own "N." section number from
    * the file order, so the titles() strings here MUST NOT include a
    * manual prefix (else the user sees "1. 1. Column").  Divbar leads
    * because it's the divbar workaround the package is built around.
    * Section order: divbar -> bar -> line -> pie -> donut, then the rest.
    * This exactly mirrors the five-chart Google Sheets recipe so a reader
    * can open the gallery and the Sheet side-by-side and see the same
    * five examples (same data, same colours) in the same sequence.  The
    * Likert long-form searchable table sits immediately after divbar so
    * a reader can pivot from the visual to the underlying rows.
    sparkta2_dashboard,                                                          ///
        files("14_divbar.html 12b_table_likert.html 02_bar.html 03_line.html 06_pie.html 07_donut.html 01_column.html 04_area.html 05_combo.html 08_scatter.html 09_bubble.html 10_geo.html 11_timeline.html 12_table.html 13_histogram.html") ///
        titles("Diverging stacked bar (Pew-style Likert)|Likert long-form (searchable table)|Bar (horizontal, with data labels)|Line (multi-series)|Pie (legend below, square frame)|Donut (legend below, square frame)|Column (same data as bar, vertical)|Area|Combo (bars + line)|Scatter|Bubble (with Play across years)|Geo (US states)|Timeline|Regions table (searchable)|Histogram") ///
        heights("700")                                                           ///
                                                                       ///
        title("googlechart v0.1.0 -- demo gallery")                              ///
        subtitle("Fourteen chart types from the Google Visualization API, wrapped for Stata.  Texas 2036 brand (Montserrat + navy/orange) applied throughout.  Requires network at view time -- googlechart loads google.charts/loader.js from gstatic.com per Google ToS.") ///
        export("`out'/00_gallery.html") noopen
}
else {
    display as text "(Skipping gallery roll-up: sparkta2_dashboard not on adopath.)"
}

display as result _n "googlechart demo gallery written to:"
display as result "  `out'"
display as result "Open 00_gallery.html in a browser to view all 14 charts on one page."
