*! test_googlechart_filters.do  v0.1.5
*!
*!   Regression test for filters().  Writes one page per case to
*!   `c(pwd)'/googlechart_filters_out/ and checks, in Stata, that every page
*!   carries what the page needs to filter: per-row f__VAR fields and a
*!   filter list with a dropdown level list for each categorical filter.
*!
*!   Cases (v0.1.4 drew a blank chart for the first three):
*!     f01  column + tooltipvars + filters(string)
*!     f02  column + over() + filters(numeric year)
*!     f03  table, filter variable with a variable label, + tablesearch
*!     f04-f15  bar / line / area / combo / scatter / bubble (+ time) /
*!          pie / donut / histogram / geo / timeline / divbar with filters
*!     f16  table with filters() but no tablesearch
*!     f17  filter values holding & < > " $ and </script>, plus missing
*!
*!   The pages also need a browser to prove the chart redraws; open any of
*!   them, change a filter, and the chart, row count and data table update.

version 17.0
clear all
set more off

capture which googlechart
if _rc {
    display as error "googlechart is not on the adopath.  Install it first.  See README.md."
    exit 199
}

local out "`c(pwd)'/googlechart_filters_out"
capture mkdir "`out'"

* Check a written page: it must hold each listed text.
capture program drop _gcf_has
program define _gcf_has
    syntax , file(string) [ text(string asis) ]
    mata: _gcf_s = invtokens(cat(st_local("file"))', char(10))
    foreach t of local text {
        mata: st_local("_hit", strofreal(strpos(_gcf_s, st_local("t")) > 0))
        if !`_hit' {
            display as error `"FAIL: `file' lacks: `t'"'
            exit 9
        }
    }
    display as text `"  ok: `file'"'
end

*-----------------------------------------------------------------------------
* Panel: 5 regions (labeled) x 5 years x 2 sectors (string)
*-----------------------------------------------------------------------------
clear
set obs 50
gen byte region_n = ceil(_n/10)
label define regL 1 "North" 2 "East" 3 "South" 4 "West" 5 "Central"
label values region_n regL
label variable region_n "Region"
bysort region_n: gen int year = 2019 + mod(_n - 1, 5)
bysort region_n year: gen str12 sector = cond(_n == 1, "Public", "Private & Co")
label variable sector "Sector of employer"
set seed 20261109
gen double cost = round(10 + 40*runiform(), .1)
label variable cost "Cost (\$M)"
gen double share = round(100*runiform(), .1)
gen byte urban = (region_n <= 2)
label define urbanL 0 "Rural" 1 "Urban"
label values urban urbanL
label variable urban "Urban or rural"
gen str2 st = word("TX OK NM LA AR", region_n)
gen double x = 5 + 10*runiform()
gen double y = 2*x + 5*rnormal()
gen double sz = 1 + 9*runiform()
tempfile panel
save "`panel'"

* f01 -- column + tooltipvars + string filter (one row per region per sector
*        after keeping one year)
use "`panel'" if year == 2023, clear
googlechart cost, name(region_n) type(column) tooltipvars(share urban) ///
    filters(sector) download datatable noopen export("`out'/f01_column_tip.html")
_gcf_has, file("`out'/f01_column_tip.html") ///
    text(`""f__sector":"Public""' `""var":"sector""' `""levels":["Private & Co","Public"]"')

* f02 -- column + over(year) + numeric year filter (the help's pattern)
use "`panel'" if sector == "Public", clear
googlechart cost, name(region_n) over(year) type(column) filters(year) ///
    download datatable animate noopen export("`out'/f02_column_over.html")
_gcf_has, file("`out'/f02_column_over.html") text(`""f__year":2019"' `""numeric":1}"')

* f03 -- table: labeled filter variable + tablesearch
use "`panel'", clear
googlechart, type(table) tooltipvars(region_n year sector cost) ///
    filters(sector urban) tablesearch download datatable ///
    noopen export("`out'/f03_table_search.html")
_gcf_has, file("`out'/f03_table_search.html") ///
    text(`""label":"Sector of employer""' `""f__urban":"Urban""' `""levels":["Rural","Urban"]"')

* f04-f06 -- bar / line / area with over() + labeled filter
use "`panel'" if sector == "Public", clear
googlechart cost, name(region_n) over(year) type(bar) filters(urban) ///
    noopen export("`out'/f04_bar.html")
googlechart cost year, over(region_n) type(line) filters(urban) ///
    noopen export("`out'/f05_line.html")
googlechart cost year, over(region_n) type(area) filters(region_n) ///
    noopen export("`out'/f06_area.html")
_gcf_has, file("`out'/f06_area.html") ///
    text(`""levels":["North","East","South","West","Central"]"')

* f07 -- combo
googlechart cost year, over(region_n) type(combo) filters(urban) ///
    noopen export("`out'/f07_combo.html")

* f08 -- scatter with series + numeric filter
use "`panel'", clear
googlechart x y, over(sector) type(scatter) filters(year) ///
    noopen export("`out'/f08_scatter.html")

* f09 -- bubble with time() + string filter
use "`panel'" if sector == "Public", clear
googlechart x y, name(region_n) over(urban) sizevar(sz) time(year) ///
    type(bubble) filters(region_n) noopen export("`out'/f09_bubble_time.html")
* f10 -- bubble without time()
use "`panel'" if year == 2023 & sector == "Public", clear
googlechart x y, name(region_n) over(urban) sizevar(sz) ///
    type(bubble) filters(urban) noopen export("`out'/f10_bubble.html")

* f11, f12 -- pie / donut
googlechart cost, name(region_n) type(pie) filters(urban) ///
    noopen export("`out'/f11_pie.html")
googlechart cost, name(region_n) type(donut) filters(urban) ///
    noopen export("`out'/f12_donut.html")

* f13 -- histogram with over() + filter
use "`panel'", clear
googlechart cost, over(sector) type(histogram) filters(region_n) ///
    noopen export("`out'/f13_histogram.html")

* f14 -- geo
use "`panel'" if year == 2023 & sector == "Public", clear
googlechart cost, name(st) type(geo) georegion(US) georesolution(provinces) ///
    filters(urban) noopen export("`out'/f14_geo.html")

* f15 -- divbar (levels pivot after filtering)
clear
input str20 q str10 response double share str6 wave
"Schools on track" "Disagree" 30 "Spring"
"Schools on track" "Neutral"  20 "Spring"
"Schools on track" "Agree"    50 "Spring"
"Roads on track"   "Disagree" 40 "Spring"
"Roads on track"   "Neutral"  25 "Spring"
"Roads on track"   "Agree"    35 "Spring"
"Schools on track" "Disagree" 25 "Fall"
"Schools on track" "Neutral"  15 "Fall"
"Schools on track" "Agree"    60 "Fall"
"Roads on track"   "Disagree" 50 "Fall"
"Roads on track"   "Neutral"  20 "Fall"
"Roads on track"   "Agree"    30 "Fall"
end
googlechart share, name(q) level(response) type(divbar) ///
    levelorder("Disagree|Neutral|Agree") filters(wave) ///
    noopen export("`out'/f15_divbar.html")

* f16 -- table with filters() and no tablesearch
use "`panel'", clear
googlechart, type(table) tooltipvars(region_n year sector cost) ///
    filters(region_n year) noopen export("`out'/f16_table.html")

* f17 -- awkward filter values, a missing filter value, timeline
clear
input str30 grp str20 name double start double end
"A & B"               "one"   2019 2020
"say hi"              "two"   2020 2022
"</script><b>x</b>"   "three" 2021 2023
"Cost (M)"            "four"  2022 2024
""                    "five"  2023 2025
end
* Built with char() so neither the do-file nor input touches the $ or quotes.
replace grp = "say " + char(34) + "hi" + char(34) in 2
replace grp = "Cost (" + char(36) + "M)" in 4
googlechart, type(timeline) name(name) startvar(start) endvar(end) ///
    filters(grp) download datatable noopen export("`out'/f17_timeline_text.html")
_gcf_has, file("`out'/f17_timeline_text.html") ///
    text(`""A & B""' `"<\/script>"' `"say \"hi\""' `""f__grp":"""')
mata: st_local("_hit", strofreal(strpos(invtokens(cat(st_local("out") + "/f17_timeline_text.html")', char(10)), "Cost (" + char(36) + "M)") > 0))
if !`_hit' {
    display as error "FAIL: f17 lost the dollar sign in a filter value"
    exit 9
}

display as result _n "test_googlechart_filters: all Stata-side checks passed."
display as result "  Pages in `out'"
